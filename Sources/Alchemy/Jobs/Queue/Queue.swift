//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import NIO

public typealias Future = EventLoopFuture

public protocol Queue {
    var eventLoop: EventLoop { get }
    func enqueue(_ job: Job) -> Future<Void>
    func dequeue() -> Future<Job?>
    func complete(_ job: JobID) -> Future<Void>
    func requeue(_ job: PersistedJob)
}
