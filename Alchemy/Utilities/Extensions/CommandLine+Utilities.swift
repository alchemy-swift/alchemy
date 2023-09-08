extension CommandLine {
    static func value(for option: String) -> String? {
        guard let index = arguments.firstIndex(of: option), let value = arguments[safe: index + 1] else {
            return nil
        }

        return value
    }

    static func hasFlag(_ flag: String) -> Bool {
        arguments.contains(flag)
    }
}
