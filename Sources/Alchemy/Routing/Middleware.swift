protocol Middleware {
    associatedtype Out
    func intercept(_ input: Request) -> Out
}
