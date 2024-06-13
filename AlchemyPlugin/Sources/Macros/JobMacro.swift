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
        return [
            Declaration("struct $\(name): Job, Codable") {

                for parameter in function.parameters {
                    "let \(parameter.name): \(parameter.type)"
                }

                Declaration("func handle(context: Context) async throws") {
                    let name = function.name.text
                    let prefix = function.callPrefixes.isEmpty ? "" : function.callPrefixes.joined(separator: " ") + " "
                    """
                    try await JobContext.$current
                        .withValue(context) {
                            \(prefix)\(name)(\(function.jobPassthroughParameterSyntax))
                        }
                    """
                }
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

    var jobParametersSignature: String {
        parameters.map {
            let name = [$0.label, $0.name]
                .compactMap { $0 }
                .joined(separator: " ")
            return "\(name): \($0.type)"
        }
        .joined(separator: ", ")
    }

    var jobPassthroughParameterSyntax: String {
        parameters.map {
            let name = [$0.label, $0.name]
                .compactMap { $0 }
                .joined(separator: " ")
            return "\(name): \($0.name)"
        }
        .joined(separator: ", ")
    }

    var callPrefixes: [String] {
        [
            isThrows ? "try" : nil,
            isAsync ? "await" : nil,
        ]
        .compactMap { $0 }
    }
}
