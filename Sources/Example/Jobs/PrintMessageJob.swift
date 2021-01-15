//
//  File.swift
//  
//
//  Created by Chris Anderson on 1/9/21.
//

import Alchemy

struct PrintMessageJob: Job {

    let title: String

    init(title: String) {
        self.title = title
    }

    func run() -> EventLoopFuture<Void> {
        print("The message from this job is: ", title)
        return EventLoopFuture.new()
    }

    func failed(error: Error) {
        print("This job failed: ", error)
    }
}
