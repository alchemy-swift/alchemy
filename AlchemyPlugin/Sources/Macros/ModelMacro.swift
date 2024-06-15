import SwiftSyntax
import SwiftSyntaxMacros

struct ModelMacro: MemberMacro, ExtensionMacro {

    // MARK: ExtensionMacro
    
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Model can only be used on a struct")
        }

        return try [
            Declaration("extension \(`struct`.name.trimmedDescription): Model {}")
        ]
        .map { try $0.extensionDeclSyntax() }
    }

    // MARK: Member Macro

    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Model can only be used on a struct")
        }

        return [
            Declaration("var storage: String") {
                `struct`.name.trimmedDescription.inQuotes
            }
        ]
        .map { $0.declSyntax() }
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
            throw AlchemyMacroError("For now, @Resource can only be applied to a struct")
        }

        return Resource(
            accessLevel: `struct`.accessLevel,
            name: `struct`.structName,
            properties: `struct`.members.map(Resource.Property.parse)
        )
    }
}

extension Resource.Property {
    static func parse(variable: VariableDeclSyntax) -> Resource.Property {
        let patterns = variable.bindings.compactMap { PatternBindingSyntax.init($0) }
        let keyword = variable.bindingSpecifier.text
        let name = "\(patterns.first!.pattern.as(IdentifierPatternSyntax.self)!.identifier.text)"
        let type = "\(patterns.first!.typeAnnotation!.type.trimmed)"
        let defaultValue = patterns.first!.initializer.map { "\($0.value.trimmed)" }
        let isStored = patterns.first?.accessorBlock == nil

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
    fileprivate func generateInitializer() -> Declaration {
        let parameters = storedProperties.map {
            if let defaultValue = $0.defaultValue {
                "\($0.name): \($0.type) = \(defaultValue)"
            } else if $0.isOptional && $0.keyword == "var" {
                "\($0.name): \($0.type) = nil"
            } else {
                "\($0.name): \($0.type)"
            }
        }
        .joined(separator: ", ")
        return Declaration("init(\(parameters))") {
            for property in storedProperties {
                "self.\(property.name) = \(property.name)"
            }
        }
        .access(accessLevel)
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
            public static let fields: [PartialKeyPath<\(name)>: ResourceField] = [
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
}

extension StructDeclSyntax {
    var structName: String {
        name.text
    }
}
