public struct PapyrusError: Error {
    public let info: String
    public init(_ info: String) { self.info = info }
}
