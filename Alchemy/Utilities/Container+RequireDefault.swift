extension Container {
    /// Requires a value of the given type, setting the default value and
    /// returning it if one doesn't exist.
    func require<T>(type: T.Type = T.self, default defaultValue: @autoclosure () -> T) -> T {
        guard let value = get(type) else {
            let defaultValue = defaultValue()
            set(defaultValue)
            return defaultValue
        }

        return value
    }
}
