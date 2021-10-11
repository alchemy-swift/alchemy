import XCTest

extension XCTestCase {
    /// Stopgap for testing async code until tests are are fixed on
    /// Linux.
    public func testAsync(timeout: TimeInterval = 0.1, _ action: @escaping () async throws -> Void) {
        let exp = expectation(description: "The async operation should complete.")
        Task {
            do {
                try await action()
                exp.fulfill()
            } catch {
                DispatchQueue.main.async {
                    XCTFail("Encountered an error in async task \(error)")
                    exp.fulfill()
                }
            }
        }
        
        wait(for: [exp], timeout: timeout)
    }
}
