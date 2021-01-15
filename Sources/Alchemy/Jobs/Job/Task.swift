//
//  File.swift
//  
//
//  Created by Chris Anderson on 1/9/21.
//

import Foundation

public protocol Task: Codable {
    func run() -> EventLoopFuture<Void>
}
