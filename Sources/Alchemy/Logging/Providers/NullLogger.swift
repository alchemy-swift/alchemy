extension Logger {
    public static var null: Logger {
        Logger(handler: { _ in })
    }
}
