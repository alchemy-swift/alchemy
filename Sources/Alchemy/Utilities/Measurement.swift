import Foundation

public func measure(_ tag: String?, action: () async throws -> Void) async throws {
    let start = Date()
    try await action()
    Log.info("'\((tag ?? "Measurement"))' \(("took " + start.elapsedString).lightBlack)")
}
