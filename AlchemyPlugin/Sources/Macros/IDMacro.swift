import SwiftSyntax
import SwiftSyntaxMacros

struct IDMacro: AccessorMacro {

    // MARK: AccessorMacro

    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw AlchemyMacroError("@ID can only be applied to a stored property.")
        }

        let property = try Resource.Property.parse(variable: variable)
        guard property.keyword == "var" else {
            throw AlchemyMacroError("Property 'id' must be a var.")
        }

        return [
            """
            get {
                guard let id = storage.id else {
                    preconditionFailure("Attempting to access 'id' from Model that doesn't have one.")
                }

                return id
            }
            """,
            "nonmutating set { storage.id = newValue }",
        ]
    }
}
