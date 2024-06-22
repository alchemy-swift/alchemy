import SwiftSyntax
import SwiftSyntaxMacros

struct ModelMacro: MemberMacro, ExtensionMacro, MemberAttributeMacro {
    
    // MARK: ExtensionMacro
    
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let resource = try Resource.parse(syntax: declaration)
        return try [
            Declaration("extension \(resource.name): Model, Codable") {
                resource.generateInitializer()
                resource.generateFields()
                resource.generateEncode()
                resource.generateDecode()
            }
        ]
        .map { try $0.extensionDeclSyntax() }
    }

    // MARK: Member Macro

    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let resource = try Resource.parse(syntax: declaration)
        return [
            resource.generateStorage(),
            resource.generateFieldLookup(),
        ]
        .map { $0.declSyntax() }
    }

    // MARK: MemberAttributeMacro

    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingAttributesFor member: some DeclSyntaxProtocol,
      in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let member = member.as(VariableDeclSyntax.self) else {
            return []
        }

        guard !member.isStatic else {
            return []
        }

        let property = try Resource.Property.parse(variable: member)
        if property.name == "id" {
            guard property.keyword == "var" else {
                throw AlchemyMacroError("Property 'id' must be a var.")
            }

            return ["@ID"]
        } else {
            return []
        }
    }
}

struct Resource {
    struct Property {
        let keyword: String
        let name: String
        let type: String
        let defaultValue: String?
        let isStored: Bool

        var isOptional: Bool {
            type.last == "?"
        }
    }

    /// The type's access level - public, private, etc
    let accessLevel: String?
    /// The type name
    let name: String
    /// The type's properties
    let properties: [Property]

    /// The type's stored properties
    var storedProperties: [Property] {
        properties.filter(\.isStored)
    }

    var storedPropertiesExceptId: [Property] {
        storedProperties.filter { $0.name != "id" }
    }
}

extension Resource {
    static func parse(syntax: DeclSyntaxProtocol) throws -> Resource {
        guard let `struct` = syntax.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("For now, @Model can only be applied to a struct")
        }

        return Resource(
            accessLevel: `struct`.accessLevel,
            name: `struct`.structName,
            properties: try `struct`.instanceMembers.map(Resource.Property.parse)
        )
    }
}

extension Resource.Property {
    static func parse(variable: VariableDeclSyntax) throws -> Resource.Property {
        let patternBindings = variable.bindings.compactMap { PatternBindingSyntax.init($0) }
        let keyword = variable.bindingSpecifier.text

        guard let patternBinding = patternBindings.first else {
            throw AlchemyMacroError("Property had no pattern bindings")
        }

        guard let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self) else {
            throw AlchemyMacroError("Unable to detect property name")
        }

        guard let typeAnnotation = patternBinding.typeAnnotation else {
            throw AlchemyMacroError("Property '\(identifierPattern.identifier.trimmedDescription)' had no type annotation")
        }

        let name = "\(identifierPattern.identifier.text)"
        let type = "\(typeAnnotation.type.trimmedDescription)"
        let defaultValue = patternBinding.initializer.map { "\($0.value.trimmed)" }
        let isStored = patternBinding.accessorBlock == nil

        return Resource.Property(
            keyword: keyword,
            name: name,
            type: type,
            defaultValue: defaultValue,
            isStored: isStored
        )
    }
}

extension Resource {
    
    // MARK: Model

    fileprivate func generateStorage() -> Declaration {
        Declaration("var storage = Storage()")
    }

    fileprivate func generateInitializer() -> Declaration {
        Declaration("init(row: SQLRow) throws") {
            "let reader = SQLRowReader(row: row, keyMapping: Self.keyMapping, jsonDecoder: Self.jsonDecoder)"
            for property in storedPropertiesExceptId {
                "self.\(property.name) = try reader.require(\(property.type).self, at: \(property.name.inQuotes))"
            }

            "try storage.read(from: reader)"
        }
        .access(accessLevel == "public" ? "public" : nil)
    }

    fileprivate func generateFields() -> Declaration {
        Declaration("func fields() throws -> SQLFields") {
            "var writer = SQLRowWriter(keyMapping: Self.keyMapping, jsonEncoder: Self.jsonEncoder)"
            for property in storedPropertiesExceptId {
                "try writer.put(\(property.name), at: \(property.name.inQuotes))"
            }
            """
            try storage.write(to: &writer)
            return writer.fields
            """
        }
        .access(accessLevel == "public" ? "public" : nil)
    }

    fileprivate func generateFieldLookup() -> Declaration {
        let fieldsString = storedProperties
            .map { property in
                let key = "\\\(name).\(property.name)"
                let defaultValue = property.defaultValue
                let defaultArgument = defaultValue.map { ", default: \($0)" } ?? ""
                let value = ".init(\(property.name.inQuotes), type: \(property.type).self\(defaultArgument))"
                return "\(key): \(value)"
            }
            .joined(separator: ",\n")
        return Declaration("""
            public static let fieldLookup: FieldLookup = [
                \(fieldsString)
            ]
            """)
    }

    // MARK: Codable

    fileprivate func generateEncode() -> Declaration {
        Declaration("func encode(to encoder: Encoder) throws") {
            if !storedPropertiesExceptId.isEmpty {
                "var container = encoder.container(keyedBy: GenericCodingKey.self)"
                for property in storedPropertiesExceptId {
                    "try container.encode(\(property.name), forKey: \(property.name.inQuotes))"
                }
            }

            "try storage.encode(to: encoder)"
        }
        .access(accessLevel == "public" ? "public" : nil)
    }

    fileprivate func generateDecode() -> Declaration {
        Declaration("init(from decoder: Decoder) throws") {
            if !storedPropertiesExceptId.isEmpty {
                "let container = try decoder.container(keyedBy: GenericCodingKey.self)"
                for property in storedPropertiesExceptId {
                    "self.\(property.name) = try container.decode(\(property.type).self, forKey: \(property.name.inQuotes))"
                }
            }

            "self.storage = try Storage(from: decoder)"
        }
        .access(accessLevel == "public" ? "public" : nil)
    }
}

extension DeclGroupSyntax {
    var hasInit: Bool {
        !initializers.isEmpty
    }

    var initializers: [InitializerDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(InitializerDeclSyntax.self) }
    }

    var accessLevel: String? {
        modifiers.first?.trimmedDescription
    }

    var members: [VariableDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }

    var instanceMembers: [VariableDeclSyntax] {
        members
            .filter { !$0.isStatic }
            .filter { $0.attributes.isEmpty }
    }
}

extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { $0.name.trimmedDescription == "static" }
    }
}

extension StructDeclSyntax {
    var structName: String {
        name.text
    }
}
