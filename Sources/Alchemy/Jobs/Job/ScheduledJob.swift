//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation

public protocol ScheduledJob: Job {
    var nextTime: Int { get }
}
