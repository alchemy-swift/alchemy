//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation

public enum Time {

    case seconds(Int)
    case minutes(Int)
    case days(Int)
    case weeks(Int)

    var unixTime: Int {
        switch self {
        case .seconds(let seconds):
            return seconds
        case .minutes(let minutes):
            return (minutes * 60)
        case .days(let days):
            return (days * 86_400)
        case .weeks(let weeks):
            return (weeks * 604_800)
        }
    }
}
