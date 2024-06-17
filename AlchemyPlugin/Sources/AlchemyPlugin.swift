#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AlchemyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JobMacro.self,
        ModelMacro.self,
        IDMacro.self,
        ApplicationMacro.self,
        ControllerMacro.self,
        HTTPMethodMacro.self,
    ]
}

#endif
