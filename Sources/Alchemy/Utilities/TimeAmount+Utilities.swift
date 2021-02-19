import Foundation
import NIO

extension TimeAmount {
    var seconds: Int {
        Int(self.nanoseconds / 1000000000)
    }
}

extension Date {
    func adding(time: TimeAmount) -> Int {
        Int(self.timeIntervalSince1970) + time.seconds
    }
}
