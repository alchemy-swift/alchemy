func makeAsync<T>(_ callbackWrapper: (Completion<T>) -> Void) async throws -> T {
    try await withCheckedThrowingContinuation { (c: CheckedContinuation<T, Error>)  in
        callbackWrapper(Completion {
            c.resume(returning: $0)
        } error: {
            c.resume(throwing: $0)
        })
    }
}

public struct Completion<T> {
    fileprivate var success: (T) -> Void
    fileprivate var error: (Error) -> Void

    public func complete(success value: T) {
        self.success(value)
    }

    public func complete(error: Error) {
        self.error(error)
    }
}
