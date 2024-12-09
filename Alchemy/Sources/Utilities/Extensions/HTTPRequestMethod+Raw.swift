extension HTTPRequest.Method {
    public static func raw(_ string: String) -> HTTPRequest.Method {
        guard let value = HTTPRequest.Method(rawValue: string) else {
            preconditionFailure("Invalid HTTP method \(string)!")
        }

        return value
    }
}
