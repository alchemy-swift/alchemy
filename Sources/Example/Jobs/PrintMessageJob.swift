//
//  File.swift
//  
//
//  Created by Chris Anderson on 1/9/21.
//

import Alchemy

struct PrintJobData: Codable {
    let title: String
}

struct PrintMessageJob: Job {
    typealias Payload = PrintJobData

    func run(payload: PrintJobData) -> EventLoopFuture<Void> {
        print("The message from this job is: ", payload.title)
        return EventLoopFuture.new()
    }

    func failed(error: Error) {
        print("This job failed: ", error)
    }
}
