import SwiftSyntax
import SwiftSyntaxMacros

/*

 1. add var storage
 2. add init(row: SQLRow)
 3. add fields: SQLFields
 4. add @ID to `var id` - if it exists.

 */

struct IDMacro: AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        [
            "get { fatalError() }",
            "nonmutating set { fatalError() }",
        ]
    }
}

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
            Declaration("extension \(resource.name): Model") {
                resource.generateInitializer()
                resource.generateFields()
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
        return property.name == "id" ? ["@ID"] : []
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
            throw AlchemyMacroError("Property \(identifierPattern.identifier.trimmedDescription) \(variable.isStatic) had no type annotation")
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

    fileprivate func generateStorage() -> Declaration {
        Declaration("let storage = ModelStorage()")
    }

    fileprivate func generateInitializer() -> Declaration {
        Declaration("init(row: SQLRow) throws") {
            for property in storedProperties where property.name != "id" {
                "self.\(property.name) = try row.require(\(property.name.inQuotes)).decode(\(property.type).self)"
            }
        }
        .access(accessLevel == "public" ? "public" : nil)
    }

    fileprivate func generateFields() -> Declaration {
        Declaration("func fields() -> SQLFields") {
            "[:]"
        }
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
        members.filter { !$0.isStatic }
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
