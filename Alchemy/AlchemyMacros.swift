@attached(extension, conformances: Application, RoutesGenerator, names: named(addGeneratedRoutes))
public macro Application() = #externalMacro(module: "AlchemyPlugin", type: "ApplicationMacro")

@attached(extension, conformances: Controller, RoutesGenerator, names: named(route))
public macro Controller() = #externalMacro(module: "AlchemyPlugin", type: "ControllerMacro")

@attached(peer, names: prefixed(`$`))
public macro Job() = #externalMacro(module: "AlchemyPlugin", type: "JobMacro")

@attached(member, names: arbitrary)
public macro Model() = #externalMacro(module: "AlchemyPlugin", type: "ModelMacro")

// MARK: Route Methods

@attached(peer, names: prefixed(`$`)) public macro HTTP(_ path: String, method: String, options: RouteOptions = []) = #externalMacro(module: "PapyrusPlugin", type: "DecoratorMacro")
@attached(peer, names: prefixed(`$`)) public macro DELETE(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro GET(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro PATCH(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro POST(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro PUT(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro OPTIONS(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro HEAD(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro TRACE(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
@attached(peer, names: prefixed(`$`)) public macro CONNECT(_ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")

// MARK: Route Parameters

@propertyWrapper public struct Path<L: LosslessStringConvertible> {
    public var wrappedValue: L

    public init(wrappedValue: L) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public struct Header<L: LosslessStringConvertible> {
    public var wrappedValue: L

    public init(wrappedValue: L) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public struct URLQuery<L: LosslessStringConvertible> {
    public var wrappedValue: L

    public init(wrappedValue: L) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public struct Field<C: Codable> {
    public var wrappedValue: C

    public init(wrappedValue: C) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper public struct Body<C: Codable> {
    public var wrappedValue: C

    public init(wrappedValue: C) {
        self.wrappedValue = wrappedValue
    }
}

