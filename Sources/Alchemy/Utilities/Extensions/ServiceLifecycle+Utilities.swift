import Foundation

extension ServiceLifecycle {
    func start() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            Lifecycle.start { error in
                if let error {
                    c.resume(throwing: error)
                } else {
                    c.resume()
                }
            }
        }
    }

    func shutdown() async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            Lifecycle.shutdown { error in
                if let error {
                    c.resume(throwing: error)
                } else {
                    c.resume()
                }
            }
        }
    }
}
