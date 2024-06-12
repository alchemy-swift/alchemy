import SwiftSyntax
import SwiftSyntaxMacros

struct JobMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard 
            let function = declaration.as(FunctionDeclSyntax.self),
            function.isStatic
        else {
            throw AlchemyMacroError("@Job can only be applied to static functions")
        }

        let name = function.name.text
        let effects = [
            function.isAsync ? "async" : nil,
            function.isThrows ? "throws" : nil,
        ]
        .compactMap { $0 }

        let effectsString = 
            if effects.isEmpty {
                ""
            } else {
                " \(effects.joined(separator: " "))"
            }

        return [
            Declaration("struct \(name.capitalizeFirst)Job: Job, Codable") {
                Declaration("func handle(context: Context) \(effectsString)") {
                    let name = function.name.text
                    let expressions = [
                        function.isThrows ? "try" : nil,
                        function.isAsync ? "await" : nil,
                    ]
                    .compactMap { $0 }

                    let expressionsString =
                        if expressions.isEmpty {
                            ""
                        } else {
                            "\(expressions.joined(separator: " ")) "
                        }

                    "\(expressionsString)\(name)()"
                }
            },

            Declaration("static func $\(name)() async throws") {
                "try await \(name.capitalizeFirst)Job().dispatch()"
            },
        ]
        .map { $0.declSyntax() }
    }
}

extension FunctionDeclSyntax {
    var isStatic: Bool {
        modifiers.map(\.name.text).contains("static")
    }

    var isAsync: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }

    var isThrows: Bool {
        signature.effectSpecifiers?.throwsSpecifier != nil
    }
}
