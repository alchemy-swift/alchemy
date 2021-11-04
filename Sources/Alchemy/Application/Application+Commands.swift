extension Application {
    /// Registers a command to your application. You can run a command
    /// by passing it's argument when you launch your app.
    ///
    /// - Parameter commandType: The type of the command to register.
    public func registerCommand<C: Command>(_ commandType: C.Type) {
        Launch.customCommands.append(commandType)
    }
    
    /// All custom commands types registered to this application.
    public var customCommands: [Command.Type] {
        Launch.customCommands
    }
}
