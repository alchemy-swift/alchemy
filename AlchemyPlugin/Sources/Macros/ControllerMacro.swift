import SwiftSyntax
import SwiftSyntaxMacros

struct ControllerMacro: ExtensionMacro {

    // MARK: ExtensionMacro

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let `struct` = declaration.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Controller can only be applied to a struct")
        }

        let routes = try Routes.parse(declaration)
        return try [
            Declaration("extension \(`struct`.name.trimmedDescription): Controller") {
                routes.routeFunction()
            },
        ]
        .map { try $0.extensionDeclSyntax() }
    }
}

extension Routes {
    func routeFunction() -> Declaration {
        Declaration("func route(_ router: Router)") {
            for endpoint in endpoints {
                "router.use($\(endpoint.name))"
            }
        }
    }
}
