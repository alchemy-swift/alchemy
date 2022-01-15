public protocol Buildable {}

extension Buildable {
    func with(build: (inout Self) -> Void) -> Self {
        var _copy = self
        build(&_copy)
        return _copy
    }
}
