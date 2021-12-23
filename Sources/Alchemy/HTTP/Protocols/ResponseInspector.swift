import NIOHTTP1

public protocol ResponseInspector: ContentInspector {
    var status: HTTPResponseStatus { get }
}
