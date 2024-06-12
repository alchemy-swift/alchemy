import SwiftSyntax
import SwiftSyntaxMacros

struct JobMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let name = declaration.as(FunctionDeclSyntax.self)?.name.text else {
            fatalError("function only")
        }

        return [
            Declaration("struct \(name.capitalizeFirst)Job: Job, Codable") {
                Declaration("func handle(context: Context) async throws") {
                    "print(\"hello from job\")"
                }
            },

            Declaration("func $\(name)() async throws") {
                "try await \(name.capitalizeFirst)Job().dispatch()"
            },
        ]
        .map { $0.declSyntax() }
    }
}
