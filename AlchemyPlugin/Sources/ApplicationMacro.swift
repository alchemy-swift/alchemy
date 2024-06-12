import SwiftSyntax
import SwiftSyntaxMacros

struct ApplicationMacro: PeerMacro, ExtensionMacro {

    /*

     1. add @main
     2. add Application
     3. register routes
     4. register jobs?

     */

    // MARK: PeerMacro

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Application can only be applied to a struct")
        }

        return []
    }

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
            Declaration("@main extension \(`struct`.name)") {},
            Declaration("extension \(`struct`.name): Application") {

            },
            Declaration("extension \(`struct`.name): RoutesGenerator") {
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
    func handlerExpression() -> Declaration {
        Declaration(method.lowercased() + path.inQuotes.inParentheses, "req") {
            let arguments = parameters.map(\.argumentString).joined(separator: ", ").inParentheses
            let effectsExpressions = [
                isThrows ? "try" : nil,
                isAsync ? "await" : nil,
            ].compactMap { $0 }

            let effectsExpressionString = effectsExpressions.isEmpty ? "" : effectsExpressions.joined(separator: " ") + " "
            "\(effectsExpressionString)\(name)\(arguments)"
        }
    }
}

extension StructDeclSyntax {
    fileprivate var attributeNames: [String] {
        attributes.map(\.trimmedDescription)
    }
}

extension EndpointParameter {
    fileprivate var argumentString: String {
        let argumentLabel = label == "_" ? nil : label ?? name
        let label = argumentLabel.map { "\($0): " } ?? ""

        guard type != "Request" else {
            return label + name
        }

        let prefix = switch kind {
        case .field: "body."
        case .query: "query."
        default:     ""
        }
        return label + prefix + name
    }
}

