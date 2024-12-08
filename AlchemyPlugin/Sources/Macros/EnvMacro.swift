import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

enum EnvMacro: AccessorMacro {
    static let formatMode: FormatMode = .disabled

    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws (AlchemyMacroError) -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw "@Env can only be applied to variables"
        }

        guard let type = variable.type else {
            throw "Unable to infer type - please add an explicit type"
        }

        let key: String
        if
            let arguments = node.arguments,
            let list = LabeledExprListSyntax(arguments),
            let first = list.first?.expression
        {
            key = first.trimmedDescription
        } else {
            key = variable.name.screamingSnake.inQuotes
        }

        let def = variable.initializerExpression.map { ", default: \($0.trimmedDescription)" } ?? ""
        return [
            """
            get { Env.require(\(raw: key), as: \(raw: type).self\(raw: def)) }
            set { Env.override(\(raw: key), with: newValue) }
            """
        ]
    }
}

private extension String {
    var screamingSnake: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: utf16.count)
        let result = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
        return result.uppercased()
    }
}

/*
 var maxUploadSize: Int {
     get {
         guard let value = get("MAX_UPLOAD_SIZE", as: Int.self) else {
             return 2 * 1024 * 1024
         }

         return value
     }
     set {
         processVariables["MAX_UPLOAD_SIZE"] = String(newValue)
     }
 }
 */
