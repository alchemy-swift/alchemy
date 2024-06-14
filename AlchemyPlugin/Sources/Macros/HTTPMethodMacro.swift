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

        guard let route = try Routes.Route.parse(function) else {
            throw AlchemyMacroError("Unable to parse function for @\(node.name)")
        }

        var expressions: [String] = []
        for parameter in route.parameters {
            if let validation = parameter.validation {
                expressions.append("\(validation) var \(parameter.name) = \(parameter.parseExpression)")
                expressions.append("try await $\(parameter.name).validate()")
                expressions.append("")
            } else {
                expressions.append("let \(parameter.name) = \(parameter.parseExpression)")
            }
        }

        let arguments = route.parameters
            .map { $0.argumentLabel + $0.name }
            .joined(separator: ", ")


        expressions.append("return " + route.effectsExpression + route.name + arguments.inParentheses)

        return [
            Declaration("var $\(route.name): Route") {
                let options = route.options.map { "\n    options: \($0)," } ?? ""
                """
                Route(
                    method: .\(route.method),
                    path: \(route.path.inQuotes),\(options)
                    handler: { req in
                        \(expressions.joined(separator: "\n        "))
                    }
                )
                """
            },
        ]
        .map { $0.declSyntax() }
    }
}

extension Routes.Route {
    fileprivate var routeParametersExpression: String {
        [path.inQuotes, options.map { "options: \($0)" }]
            .compactMap { $0 }
            .joined(separator: ", ")
            .inParentheses
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
    var argumentLabel2: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        return argumentLabel.map { "\($0): " } ?? ""
    }

    var parseExpression2: String {
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

/*
 var _body: Route {
     Route(
         method: .POST,
         path: "/body",
         handler: { req in
             @Validate(.email) var thing = try req.content.thing.decode(String.self)
             try await $thing.validate()
             return body(thing: thing)
         }
     )
 }
 */
