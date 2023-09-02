public protocol ResponseBuilder: HTTPBuilder {
    var status: HTTPResponseStatus { get set }
}
