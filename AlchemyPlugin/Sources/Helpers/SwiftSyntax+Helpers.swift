import SwiftSyntax

extension AttributeSyntax {
    var name: String {
        attributeName.trimmedDescription
    }
}

extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { $0.name.trimmedDescription == "static" }
    }

    var name: String {
        firstBinding?.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription ?? "unknown"
    }

    var type: String? {
        firstBinding?.typeAnnotation?.type.trimmedDescription ?? initializerExpression?.inferType()
    }

    var initializerExpression: ExprSyntax? {
        bindings.first?.initializer?.value
    }

    private var firstBinding: PatternBindingSyntax? {
        bindings.first
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
        signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
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

extension ExprSyntax {
    fileprivate func inferType() -> String? {
        if `is`(IntegerLiteralExprSyntax.self) {
            return "Int"
        } else if `is`(StringLiteralExprSyntax.self) {
            return "String"
        } else if `is`(BooleanLiteralExprSyntax.self) {
            return "Bool"
        } else if `is`(FloatLiteralExprSyntax.self) {
            return "Double"
        } else if
            let function = FunctionCallExprSyntax(self),
            let declReference = DeclReferenceExprSyntax(function.calledExpression),
            declReference.isLikelyType
        {
            return declReference.baseName.text
        } else if let ternary = TernaryExprSyntax(self) {
            return ternary.thenExpression.inferType()
        } else if
            let sequence = SequenceExprSyntax(self),
            sequence.elements.count > 1,
            let ternary = sequence.elements.compactMap({ UnresolvedTernaryExprSyntax($0) }).first
        {
            return ternary.thenExpression.inferType()
        } else {
            return nil
        }
    }
}

extension DeclReferenceExprSyntax {
    fileprivate var isLikelyType: Bool {
        guard let first = baseName.text.first else { return false }
        return first == "_" || first.isUppercase
    }
}
