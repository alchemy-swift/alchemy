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
        Declaration(prefix + method.lowercased() + routeParametersExpression, "req") {
            for parameter in parameters {
                if let validation = parameter.validation {
                    "\(validation) var \(parameter.name) = \(parameter.parseExpression)"
                    "try await $\(parameter.name).validate()"
                    ""
                } else {
                    "let \(parameter.name) = \(parameter.parseExpression)"
                }
            }

            let arguments = parameters
                .map { $0.argumentLabel + $0.name }
                .joined(separator: ", ")


            "return " + effectsExpression + name + arguments.inParentheses
        }
    }

    private var routeParametersExpression: String {
        [path.inQuotes, options.map { "options: \($0)" }]
            .compactMap { $0 }
            .joined(separator: ", ")
            .inParentheses
    }

    private var effectsExpression: String {
        let effectsExpressions = [
            isThrows ? "try" : nil,
            isAsync ? "await" : nil,
        ].compactMap { $0 }

        return effectsExpressions.isEmpty ? "" : effectsExpressions.joined(separator: " ") + " "
    }
}

extension EndpointParameter {
    var argumentLabel: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        return argumentLabel.map { "\($0): " } ?? ""
    }

    var parseExpression: String {
        guard type != "Request" else {
            return "req"
        }

        switch kind {
        case .field: 
            return "try req.content.\(name).decode(\(type).self)"
        case .query:
            return "try req.requireQuery(\(name.inQuotes), as: \(type).self)"
        case .path:
            return "try req.requireParameter(\(name.inQuotes), as: \(type).self)"
        case .header:
            return "try req.requireHeader(\(name.inQuotes))"
        case .body:
            return "try req.content.decode(\(type).self)"
        }
    }
}
