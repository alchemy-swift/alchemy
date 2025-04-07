@testable import Alchemy

extension MemoryQueue {
    public func expectNothingPushed(sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(jobs.isEmpty, sourceLocation: sourceLocation)
    }
    
    public func expectNotPushed<J: Job>(_ type: J.Type, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(!jobs.values.contains { $0.jobName == J.name }, sourceLocation: sourceLocation)
    }
    
    public func expectPushed<J: Job>(on channel: String? = nil,
                                     _ type: J.Type,
                                     _ count: Int = 1,
                                     sourceLocation: SourceLocation = #_sourceLocation) {
        let matches = jobs.values.filter { $0.jobName == J.name && $0.channel == channel ?? $0.channel }
        #expect(matches.count == count, sourceLocation: sourceLocation)
    }
    
    public func expectPushed<J: Job>(on channel: String? = nil,
                                     _ type: J.Type,
                                     expectation: (J) -> Bool,
                                     sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for job in jobs.values {
            guard job.jobName == J.name, job.channel == channel ?? job.channel else {
                continue
            }

            if (try await Jobs.createJob(from: job) as? J).map(expectation) ?? false {
                return
            }
        }

        Issue.record(sourceLocation: sourceLocation)
    }
    
    public func expectPushed<J: Job & Equatable>(
        on channel: String? = nil,
        _ instance: J,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async throws {
        for job in jobs.values {
            guard job.jobName == J.name, job.channel == channel ?? job.channel else {
                continue
            }

            if (try await Jobs.createJob(from: job) as? J) == instance {
                return
            }
        }

        Issue.record(sourceLocation: sourceLocation)
    }
}
