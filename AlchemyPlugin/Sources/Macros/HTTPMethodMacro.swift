import SwiftSyntax
import SwiftSyntaxMacros

struct HTTPMethodMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw AlchemyMacroError("@\(node.name) can only be applied to functions")
        }

        guard let endpoint = try Endpoint.parse(function) else {
            throw AlchemyMacroError("Unable to parse function for @\(node.name)")
        }

        return [
            endpoint.routeDeclaration()
        ]
        .map { $0.declSyntax() }
    }
}

extension Endpoint {
    fileprivate func routeDeclaration() -> Declaration {
        Declaration("var $\(name): Route") {
            let options = options.map { "\n    options: \($0)," } ?? ""
            let closureArgument = parameters.isEmpty ? "_" : "req"
            let returnType = responseType ?? "Void"
            """
            Route(
                method: .\(method),
                path: \(path.inQuotes),\(options)
                handler: { \(closureArgument) -> \(returnType) in
                    \(parseExpressionsString)
                }
            )
            """
        }
    }

    fileprivate var argumentsString: String {
        parameters
            .map { parameter in
                if parameter.type == "Request" {
                    parameter.argumentLabel + "req"
                } else {
                    parameter.argumentLabel + parameter.name
                }
            }
            .joined(separator: ", ")
    }

    fileprivate var parseExpressionsString: String {
        var expressions: [String] = []
        for parameter in parameters where parameter.type != "Request" {
            if let validation = parameter.validation {
                expressions.append("\(validation) var \(parameter.name) = \(parameter.parseExpression)")
                expressions.append("try await $\(parameter.name).validate()")
            } else {
                expressions.append("let \(parameter.name) = \(parameter.parseExpression)")
            }
        }

        let returnExpression = responseType != nil ? "return " : ""
        expressions.append(returnExpression + effectsExpression + name + argumentsString.inParentheses)
        return expressions.joined(separator: "\n        ")
    }

    fileprivate var effectsExpression: String {
        let effectsExpressions = [
            isThrows ? "try" : nil,
            isAsync ? "await" : nil,
        ].compactMap { $0 }

        return effectsExpressions.isEmpty ? "" : effectsExpressions.joined(separator: " ") + " "
    }
}

extension EndpointParameter {
    fileprivate var argumentLabel: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        return argumentLabel.map { "\($0): " } ?? ""
    }

    fileprivate var parseExpression: String {
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
