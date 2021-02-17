//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import RediStack

public struct RedisJob: PersistedJob {

    public let id: JobID
    public let name: String
    public var payload: JSONData
    public var attempts: Int = 0

    var key: String {
        "job:\(self.id)"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case attempts
        case payload
    }

    init(id: JobID, name: String, payload: Data) {
        self.id = id
        self.name = name
        self.payload = JSONData(data: payload)
    }
}

public class RedisQueue: Queue {
    public typealias QueueItem = RedisJob

    public var redis: Redis

    var isEmpty: Bool {
        return self.pending.isEmpty
    }

    private var jobs: [JobID: MemoryJob] = [:]

    private var delayed: [JobID] = []

    private var pending: [JobID] = []

    //    private var failed: [Job] = []

    public init(redis: Redis) {
        self.redis = redis
    }

    @discardableResult
    public func enqueue<T: Job>(_ type: T.Type, _ payload: T.Payload) -> EventLoopFuture<Void> {
        let identifier = UUID().uuidString
        let payloadData = try! T.serializePayload(payload)
        return self.requeue(
            MemoryJob(
                id: identifier,
                name: T.name,
                payload: payloadData
            )
        )
    }

    public func dequeue() -> EventLoopFuture<QueueItem?> {

        self.redis.rpoplpush(from: <#T##RedisKey#>, to: <#T##RedisKey#>)

        RedisKey(<#T##key: String##String#>)
        self.redis.get(<#T##key: RedisKey##RedisKey#>)


        guard let jobId = self.nextId(),
              let job = self.jobs[jobId] else {
            return eventLoop.makeSucceededFuture(nil)
        }
        return eventLoop.makeSucceededFuture(job)
    }

    public func complete(_ item: QueueItem, success: Bool) -> EventLoopFuture<Void> {
        self.redis.lrem(RedisKey(item.id), from: RedisKey(self.processingKey)).flatMap { _ in
            self.redis.delete(RedisKey(item.key))
        }.map { _ in }
        return eventLoop.makeSucceededFuture(())
    }

    public func requeue(_ item: QueueItem) -> EventLoopFuture<Void> {
//        self.redis.lpush(RedisKey("queue"), values: )
        self.redis.set(RedisKey(item.key), toJSON: item)
    }

    private func nextId() -> JobID? {
        //        let nextPeriodicJobId = self.delayed.first {
        //            if let nextPeriodicJob = self.jobs[$0]?.job as? PeriodicJob {
        //                return nextPeriodicJob.shouldProcess
        //            }
        //            return false
        //        }
        //        if let nextJobId = nextPeriodicJobId {
        //            return nextJobId
        //        }
        if !isEmpty {
            return self.pending.removeFirst()
        }
        return nil
    }
}

fileprivate extension RedisClient {
    func get<D>(_ key: RedisKey, asJSON type: D.Type) -> EventLoopFuture<D?> where D: Decodable {
        return get(key, as: Data.self).flatMapThrowing { data in
            return try data.flatMap { data in
                return try JSONDecoder().decode(D.self, from: data)
            }
        }
    }

    func set<E>(_ key: RedisKey, toJSON entity: E) -> EventLoopFuture<Void> where E: Encodable {
        do {
            return try set(key, to: JSONEncoder().encode(entity))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
