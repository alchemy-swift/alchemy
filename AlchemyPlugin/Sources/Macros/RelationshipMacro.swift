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
                try await $\(raw: declaration.name).get()
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

        return [
            Declaration("var $\(declaration.name): \(node.name)<\(declaration.type).Element>") {
                "\(node.name.lowercaseFirst)().named(\(declaration.name.inQuotes))"
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

/*
 @HasMany var todos: [Todo] {
     get async throws {
         try await $todos.get()
     }
 }

 var $todos: HasMany<Todo> {
     hasMany(from: "id", to: "id")
 }
 */
