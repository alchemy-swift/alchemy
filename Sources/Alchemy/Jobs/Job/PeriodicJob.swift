//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import NIO

public protocol PeriodicJob: ScheduledJob {
    var frequency: Frequency { get }
}

extension PeriodicJob {
    public var shouldProcess: Bool {
        return frequency.timeUntilNext().nanoseconds > 0
    }
}
