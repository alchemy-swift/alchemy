@attached(extension, conformances: Application, Controller, names: named(route))
public macro Application() = #externalMacro(module: "AlchemyPlugin", type: "ApplicationMacro")

@attached(extension, conformances: Controller, names: named(route))
public macro Controller() = #externalMacro(module: "AlchemyPlugin", type: "ControllerMacro")

@attached(accessor)
public macro Env(_ key: String? = nil) = #externalMacro(module: "AlchemyPlugin", type: "EnvMacro")

@attached(peer, names: prefixed(`$`))
public macro Job() = #externalMacro(module: "AlchemyPlugin", type: "JobMacro")

// MARK: Rune - Model

@attached(memberAttribute)
@attached(member, names: named(storage), named(fieldLookup))
@attached(extension, conformances: Model, Codable, names: named(init), named(fields), named(encode))
public macro Model() = #externalMacro(module: "AlchemyPlugin", type: "ModelMacro")

@attached(accessor)
public macro ID() = #externalMacro(module: "AlchemyPlugin", type: "IDMacro")

// MARK: Rune - Relationships

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro HasMany(from: String? = nil, to: String? = nil) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro HasManyThrough(
    _ through: String,
    from: String? = nil,
    to: String? = nil,
    throughFrom: String? = nil,
    throughTo: String? = nil
) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro HasOne(from: String? = nil, to: String? = nil) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro HasOneThrough(
    _ through: String,
    from: String? = nil,
    to: String? = nil,
    throughFrom: String? = nil,
    throughTo: String? = nil
) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro BelongsTo(from: String? = nil, to: String? = nil) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro BelongsToThrough(
    _ through: String,
    from: String? = nil,
    to: String? = nil,
    throughFrom: String? = nil,
    throughTo: String? = nil
) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`))
public macro BelongsToMany(
    _ pivot: String? = nil,
    from: String? = nil,
    to: String? = nil,
    pivotFrom: String? = nil,
    pivotTo: String? = nil
) = #externalMacro(module: "AlchemyPlugin", type: "RelationshipMacro")

// MARK: Route Methods

@attached(peer, names: prefixed(`$`)) public macro HTTP(_ method: String, _ path: String, options: RouteOptions = []) = #externalMacro(module: "AlchemyPlugin", type: "HTTPMethodMacro")
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

