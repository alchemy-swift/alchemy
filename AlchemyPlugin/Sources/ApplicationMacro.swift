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

        return try [
            Declaration("@main extension \(`struct`.name): Application") {

            }
            .extensionDeclSyntax()
        ]
    }
}

extension StructDeclSyntax {
    fileprivate var attributeNames: [String] {
        attributes.map(\.trimmedDescription)
    }
}
