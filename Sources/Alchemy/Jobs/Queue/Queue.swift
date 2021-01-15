//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import NIO

public protocol Queue {
    var eventLoop: EventLoop { get set }
    @discardableResult
    func enqueue<T: Job>(_ job: T) -> EventLoopFuture<Void>
    func dequeue() -> EventLoopFuture<PersistedJob?>
    func complete(_ item: PersistedJob, success: Bool) -> EventLoopFuture<Void>
    func requeue(_ item: PersistedJob) -> EventLoopFuture<Void>
}
