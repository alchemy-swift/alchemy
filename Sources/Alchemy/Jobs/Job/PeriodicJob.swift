//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation

public protocol PeriodicJob: ScheduledJob {
    var frequency: PeriodicTime { get }
}

extension PeriodicJob {
    public var nextTime: Int {
        return frequency.nextTime
    }
}
