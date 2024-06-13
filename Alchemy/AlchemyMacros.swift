@attached(peer, names: prefixed(`$`))
public macro Job() = #externalMacro(module: "AlchemyPlugin", type: "JobMacro")

@attached(member, names: arbitrary)
public macro Model() = #externalMacro(module: "AlchemyPlugin", type: "ModelMacro")

@attached(
    extension,
    conformances:
        Application,
        RoutesGenerator,
    names:
        named(addGeneratedRoutes)
)
public macro Application() = #externalMacro(module: "AlchemyPlugin", type: "ApplicationMacro")

@attached(
    extension,
    conformances:
        Controller,
        RoutesGenerator,
    names:
        named(route)
)
public macro Controller() = #externalMacro(module: "AlchemyPlugin", type: "ControllerMacro")
