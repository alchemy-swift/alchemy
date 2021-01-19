//
//  File.swift
//  
//
//  Created by Chris Anderson on 1/9/21.
//

import Foundation

public protocol Task {
    func run(payload: Data) -> EventLoopFuture<Void>
    var recoveryStrategy: RecoveryStrategy { get }
}

extension Task {
    var name: String { Self.name }
    public static var name: String {
        return String(describing: Self.self)
    }

    public var recoveryStrategy: RecoveryStrategy { .none }
}
