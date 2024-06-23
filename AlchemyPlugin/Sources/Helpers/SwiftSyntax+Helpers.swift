import SwiftSyntax

extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { $0.name.trimmedDescription == "static" }
    }

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
