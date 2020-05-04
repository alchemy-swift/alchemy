/// Something to make HTTP requests from the server.
///
/// Might not be necessary with the newly christened https://github.com/swift-server/async-http-client
/// Haven't looked @ the docs but maybe they could be prettified.
struct Client {
    func request() {
        
    }
}

extension Client: FactoryService {
    static var factory: (Container) throws -> Client = { _ in Client() }
}
