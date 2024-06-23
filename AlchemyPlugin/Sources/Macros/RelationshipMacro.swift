import SwiftSyntax
import SwiftSyntaxMacros

public enum RelationshipMacro: AccessorMacro, PeerMacro {

    // MARK: AccessorMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw AlchemyMacroError("@\(node.name) can only be applied to variables")
        }

        return [
            """
            get async throws {
                try await $\(raw: declaration.name).value()
            }
            """
        ]
    }

    // MARK: PeerMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(VariableDeclSyntax.self) else {
            throw AlchemyMacroError("@\(node.name) can only be applied to variables")
        }

        let arguments = node.arguments.map { "\($0.trimmedDescription)" } ?? ""
        return [
            Declaration("var $\(declaration.name): \(node.name)<\(declaration.type)>") {
                """
                \(node.name.lowercaseFirst)(\(arguments))
                    .named(\(declaration.name.inQuotes))
                """
            }
        ]
        .map { $0.declSyntax() }
    }
}

extension String {
    var lowercaseFirst: String {
        prefix(1).lowercased() + dropFirst()
    }
}

extension VariableDeclSyntax {
    var name: String {
        bindings.compactMap {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmedDescription
        }.first ?? "unknown"
    }

    var type: String {
        bindings.compactMap {
            $0.typeAnnotation?.type.trimmedDescription
        }.first ?? "unknown"
    }
}
