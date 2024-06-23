import SwiftSyntax
import SwiftSyntaxMacros

struct ModelMacro: MemberMacro, MemberAttributeMacro, ExtensionMacro {

    // MARK: Member Macro

    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let resource = try Model.parse(syntax: declaration)
        return [
            resource.generateStorage(),
            declaration.hasFieldLookupFunction ? nil : resource.generateFieldLookup(),
        ]
        .compactMap { $0?.declSyntax() }
    }

    // MARK: MemberAttributeMacro

    static func expansion(
      of node: AttributeSyntax,
      attachedTo declaration: some DeclGroupSyntax,
      providingAttributesFor member: some DeclSyntaxProtocol,
      in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let member = member.as(VariableDeclSyntax.self), !member.isStatic else {
            return []
        }

        let property = try Model.Property.parse(variable: member)
        guard property.name == "id" else { return [] }
        guard property.keyword == "var" else {
            throw AlchemyMacroError("Property 'id' must be a var.")
        }

        return ["@ID"]
    }

    // MARK: ExtensionMacro

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let resource = try Model.parse(syntax: declaration)
        return try [
            Declaration("extension \(resource.name): Model, Codable") {
                if !declaration.hasModelInit { resource.generateModelInit() }
                if !declaration.hasFieldsFunction { resource.generateFields() }
                if !declaration.hasDecodeInit { resource.generateDecode() }
                if !declaration.hasEncodeFunction { resource.generateEncode() }
            }
        ]
        .map { try $0.extensionDeclSyntax() }
    }
}

extension Model {
    
    // MARK: Model

    fileprivate func generateStorage() -> Declaration {
        let id = idProperty.flatMap(\.defaultValue).map { "id: \($0)" } ?? ""
        return Declaration("var storage = Storage(\(id))")
            .access(accessLevel == "public" ? "public" : nil)
    }

    fileprivate func generateModelInit() -> Declaration {
        Declaration("init(row: SQLRow) throws") {
            "let reader = SQLRowReader(row: row, keyMapping: Self.keyMapping, jsonDecoder: Self.jsonDecoder)"
            for property in storedPropertiesExceptId {
                "self.\(property.name) = try reader.require(\\Self.\(property.name), at: \(property.name.inQuotes))"
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
        Declaration(
            """
            static let fieldLookup: FieldLookup = [
                \(
                    storedProperties
                        .map { property in
                            let key = "\\\(name).\(property.name)"
                            let defaultValue = property.defaultValue
                            let defaultArgument = defaultValue.map { ", default: \($0)" } ?? ""
                            let value = "Field(\(property.name.inQuotes), path: \(key)\(defaultArgument))"
                            return "\(key): \(value)"
                        }
                        .joined(separator: ",\n")
                )
            ]
            """
        ).access(accessLevel == "public" ? "public" : nil)
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
                    "self.\(property.name) = try container.decode(\\Self.\(property.name), forKey: \(property.name.inQuotes))"
                }
            }

            "self.storage = try Storage(from: decoder)"
        }
        .access(accessLevel == "public" ? "public" : nil)
    }
}

extension DeclGroupSyntax {
    fileprivate var hasModelInit: Bool {
        initializers.map(\.trimmedDescription).contains { $0.contains("init(row: SQLRow)") }
    }

    fileprivate var hasDecodeInit: Bool {
        initializers.map(\.trimmedDescription).contains { $0.contains("init(from decoder: Decoder)") }
    }

    fileprivate var hasEncodeFunction: Bool {
        functions.map(\.trimmedDescription).contains { $0.contains("func encode(to encoder: Encoder)") }
    }

    fileprivate var hasFieldsFunction: Bool {
        functions.map(\.trimmedDescription).contains { $0.contains("func fields() throws -> SQLFields") }
    }

    fileprivate var hasFieldLookupFunction: Bool {
        functions.map(\.trimmedDescription).contains { $0.contains("fieldLookup: FieldLookup") }
    }
}
