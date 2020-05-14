public struct Empty: Codable { public init() {} }

extension Empty: RequestLoadable {
    public init(from decoder: RequestDecoder) throws {
        self.init()
    }
}
