import Foundation

extension Duration {
    /// This time amount in seconds.
    var seconds: Int {
        Int(components.seconds)
    }
}

extension Date {
    /// Epoch seconds after adding a time amount to this date.
    ///
    /// - Parameter time: The time amount to add.
    /// - Returns: The epoch seconds from adding `time` to this date.
    func adding(time: Duration) -> Int {
        Int(timeIntervalSince1970) + time.seconds
    }
}
