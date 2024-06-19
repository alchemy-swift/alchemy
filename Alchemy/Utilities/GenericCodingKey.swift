public struct GenericCodingKey: CodingKey, ExpressibleByStringLiteral {
    public let stringValue: String
    public let intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public static func key(_ string: String) -> GenericCodingKey {
        .init(stringValue: string)
    }

    // MARK: ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.init(stringValue: value)
    }
}
