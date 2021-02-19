import Foundation

public protocol ScheduledJob: Job {
    var nextTime: Int { get }
}
