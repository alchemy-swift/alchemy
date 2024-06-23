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

        let routes = try EndpointGroup.parse(declaration)
        return try [
            Declaration("extension \(`struct`.name.trimmedDescription): Application, Controller") {
                routes.routeFunction()
            },
        ]
        .map { try $0.extensionDeclSyntax() }
    }
}
