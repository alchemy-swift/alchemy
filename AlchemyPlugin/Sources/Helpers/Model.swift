import SwiftSyntax

struct Model {
    struct Property {
        /// either let or var
        let keyword: String
        let name: String
        let type: String?
        let defaultValue: String?
        let isStored: Bool
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

    var idProperty: Property? {
        storedProperties.filter { $0.name == "id" }.first
    }
}

extension Model {
    static func parse(syntax: DeclSyntaxProtocol) throws -> Model {
        guard let `struct` = syntax.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("For now, @Model can only be applied to a struct")
        }

        return Model(
            accessLevel: `struct`.accessLevel,
            name: `struct`.structName,
            properties: try `struct`.instanceMembers.map(Model.Property.parse)
        )
    }
}

extension Model.Property {
    static func parse(variable: VariableDeclSyntax) throws -> Model.Property {
        let patternBindings = variable.bindings.compactMap { PatternBindingSyntax.init($0) }
        let keyword = variable.bindingSpecifier.text

        guard let patternBinding = patternBindings.first else {
            throw AlchemyMacroError("Property had no pattern bindings")
        }

        guard let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self) else {
            throw AlchemyMacroError("Unable to detect property name")
        }

        let name = "\(identifierPattern.identifier.text)"
        let type = patternBinding.typeAnnotation?.type.trimmedDescription
        let defaultValue = patternBinding.initializer.map { "\($0.value.trimmed)" }
        let isStored = patternBinding.accessorBlock == nil

        return Model.Property(
            keyword: keyword,
            name: name,
            type: type,
            defaultValue: defaultValue,
            isStored: isStored
        )
    }
}

extension DeclGroupSyntax {
    fileprivate var accessLevel: String? {
        modifiers.first?.trimmedDescription
    }

    var functions: [FunctionDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    var initializers: [InitializerDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
    }

    var variables: [VariableDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }

    fileprivate var instanceMembers: [VariableDeclSyntax] {
        variables
            .filter { !$0.isStatic }
            .filter { $0.attributes.isEmpty }
    }
}

extension StructDeclSyntax {
    fileprivate var structName: String {
        name.text
    }
}
