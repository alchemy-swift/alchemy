//
//  File.swift
//  
//
//  Created by Chris Anderson on 1/24/21.
//

import Foundation

public protocol PersistedJob: Codable {

    var name: String { get }
    var attempts: Int { get set }
    var payload: JSONData { get set }

    func run(job: AnyJob) -> EventLoopFuture<Void>
    func shouldRetry(maxRetries: Int) -> Bool
    mutating func retry()
}

extension PersistedJob {
    public func run(job: AnyJob) -> EventLoopFuture<Void> {
        job.run(payload: self.payload.data)
    }

    public func shouldRetry(maxRetries: Int) -> Bool {
        self.attempts < maxRetries
    }

    public mutating func retry() {
        self.attempts += 1
    }
}
