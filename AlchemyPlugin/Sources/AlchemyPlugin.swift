#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AlchemyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        
        // MARK: Jobs

        JobMacro.self,

        // MARK: Rune

        ModelMacro.self,
        IDMacro.self,
        RelationshipMacro.self,

        // MARK: Routing

        ApplicationMacro.self,
        ControllerMacro.self,
        HTTPMethodMacro.self,
    ]
}

#endif
