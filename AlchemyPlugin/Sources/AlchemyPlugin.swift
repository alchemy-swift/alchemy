#if canImport(SwiftCompilerPlugin)

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AlchemyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JobMacro.self,
        ModelMacro.self,
        ApplicationMacro.self,
        ControllerMacro.self,
    ]
}

#endif

/*
 
 # Routes

 - @Routes at top level searches for REST annotated functions
    - constructs 

 # Jobs

 # Model



 */
// @Model
// @Routes
// @Application
// @Controller
