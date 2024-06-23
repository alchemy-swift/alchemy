import SwiftSyntax

extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { $0.name.trimmedDescription == "static" }
    }

    var name: String {
        bindings.compactMap {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription
        }.first ?? "unknown"
    }

    var type: String {
        bindings.compactMap {
            $0.typeAnnotation?.type.trimmedDescription
        }.first ?? "unknown"
    }
}

extension FunctionDeclSyntax {

    // MARK: Function effects & attributes

    var functionName: String {
        name.text
    }

    var parameters: [FunctionParameterSyntax] {
        signature
            .parameterClause
            .parameters
            .compactMap { FunctionParameterSyntax($0) }
    }

    var functionAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }

    var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }

    // MARK: Return Data

    var returnType: String? {
        signature.returnClause?.type.trimmedDescription
    }
}

extension FunctionParameterSyntax {
    var label: String? {
        secondName != nil ? firstName.text : nil
    }

    var name: String {
        (secondName ?? firstName).text
    }

    var typeName: String {
        trimmed.type.trimmedDescription
    }

    var parameterAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}

extension AttributeSyntax {
    var name: String {
        attributeName.trimmedDescription
    }
}
