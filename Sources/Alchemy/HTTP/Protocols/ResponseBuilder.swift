import NIOHTTP1

public protocol ResponseBuilder: ContentBuilder {
    var status: HTTPResponseStatus { get set }
}
