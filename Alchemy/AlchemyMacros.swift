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

// MARK: Routes

@attached(peer)
public macro HTTP(_ path: String, method: String) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro DELETE(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro GET(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro PATCH(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro POST(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro PUT(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro OPTIONS(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro HEAD(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro TRACE(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

@attached(peer)
public macro CONNECT(_ path: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")

// MARK: Route Parameters

public typealias Path<T> = T
public typealias Header<T> = T
//public typealias Query<T> = T
public typealias Field<T> = T
public typealias Body<T> = T

