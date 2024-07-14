public protocol ResponseBuilder: HTTPBuilder {
    var status: HTTPResponse.Status { get set }
}
