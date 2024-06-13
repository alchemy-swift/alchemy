import SwiftSyntax
import SwiftSyntaxMacros

struct ApplicationMacro: ExtensionMacro {

    // MARK: ExtensionMacro

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Application can only be applied to a struct")
        }

        let routes = try Routes.parse(declaration)

        return try [
            Declaration("@main extension \(`struct`.name.trimmedDescription)") {},
            Declaration("extension \(`struct`.name.trimmedDescription): Application") {},
            Declaration("extension \(`struct`.name.trimmedDescription): RoutesGenerator") {
                routes.generatedRoutesFunction()
            },
        ]
        .map { try $0.extensionDeclSyntax() }
    }
}

extension Routes {
    func generatedRoutesFunction() -> Declaration {
        Declaration("func addGeneratedRoutes()") {
            for route in routes {
                route.handlerExpression()
            }
        }
    }
}

extension Routes.Route {
    func handlerExpression(prefix: String = "") -> Declaration {
        Declaration(prefix + method.lowercased() + path.inQuotes.inParentheses, "req") {
            let arguments = parameters.map(\.argumentString).joined(separator: ",\n    ")
            let effectsExpressions = [
                isThrows ? "try" : nil,
                isAsync ? "await" : nil,
            ].compactMap { $0 }

            let effectsExpressionString = effectsExpressions.isEmpty ? "" : effectsExpressions.joined(separator: " ") + " "
            """
            return \(effectsExpressionString)\(name)(
                \(arguments)
            )
            """
        }
    }
}

extension EndpointParameter {
    var argumentString: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        let label = argumentLabel.map { "\($0): " } ?? ""

        guard type != "Request" else {
            return label + "req"
        }

        switch kind {
        case .field: 
            return label + "try req.content.\(name).decode(\(type).self)"
        case .query:
            return label + "try req.requireQuery(\(name.inQuotes), as: \(type).self)"
        case .path:
            return label + "try req.requireParameter(\(name.inQuotes), as: \(type).self)"
        case .header:
            return label + "try req.requireHeader(\(name.inQuotes))"
        case .body:
            return label + "try req.content.decode(\(type).self)"
        }
    }
}

