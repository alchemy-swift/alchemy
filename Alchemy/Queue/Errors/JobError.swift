/// An error encountered when interacting with a `Job`.
public enum JobError: Error, Equatable {
    case unknownJob(String)
    case misc(String)

    /// Initialize with a message.
    init(_ message: String) {
        self = .misc(message)
    }
}
