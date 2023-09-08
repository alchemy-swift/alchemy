import Alchemy

extension Client.Request: RequestInspector {
    public var container: Container { Container() }
}
