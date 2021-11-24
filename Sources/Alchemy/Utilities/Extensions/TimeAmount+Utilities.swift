import Foundation
import NIO

extension TimeAmount {
    /// This time amount in seconds.
    var seconds: Int {
        Int(self.nanoseconds / 1000000000)
    }
}

extension Date {
    /// Epoch seconds after adding a time amount to this date.
    ///
    /// - Parameter time: The time amount to add.
    /// - Returns: The epoch seconds from adding `time` to this date.
    func adding(time: TimeAmount) -> Int {
        Int(self.timeIntervalSince1970) + time.seconds
    }
}
