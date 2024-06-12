@attached(peer, names: arbitrary)
public macro Job() = #externalMacro(module: "AlchemyPlugin", type: "JobMacro")

@attached(member, names: arbitrary)
public macro Model() = #externalMacro(module: "AlchemyPlugin", type: "ModelMacro")

@attached(peer)
@attached(
    extension,
    conformances:
        Application,
        RoutesGenerator,
    names:
        named(addGeneratedRoutes)
)
public macro Application() = #externalMacro(module: "AlchemyPlugin", type: "ApplicationMacro")

public protocol RoutesGenerator {
    func addGeneratedRoutes()
}
