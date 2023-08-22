//
//  File.swift
//  
//
//  Created by Josh Wright on 8/22/23.
//

import Foundation

public struct Loggers {
    public let loggers: [Logger.Identifier: Logger]

    public init(loggers: [Logger.Identifier : Logger] = [.default: .alchemyDefault]) {
        self.loggers = loggers
    }
}
