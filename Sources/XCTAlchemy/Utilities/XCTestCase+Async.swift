import XCTest

extension XCTestCase {
    /// Stopgap for wrapping async tests until they are fixed on Linux &
    /// available for macOS under 12
    func wrapAsync(timeout: TimeInterval = 0.1, _ action: @escaping () async throws -> Void) {
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
