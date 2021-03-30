import Fusion
import NIO
import Cron

public struct Scheduler {
    let scheduleLoop: EventLoop
    
    func schedule(schedule: Schedule, task: @escaping () throws -> Void) {
        guard let next = schedule.next()?.date else {
            return Log.error("schedule doesn't have a future date to run.")
        }

        func scheduleNextAndRun() throws -> Void {
            self.schedule(schedule: schedule, task: task)
            try task()
        }

        let delay = Int64(next.timeIntervalSinceNow * 1000)
        Services.eventLoop.scheduleTask(in: .milliseconds(delay), scheduleNextAndRun)
    }
}

extension Application {
    public func schedule(
        job: Job,
        queue: Queue = Services.queue,
        queueName: String = kDefaultQueueName
    ) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler.schedule(schedule: schedule) {
                _ = Services.eventLoop
                    .flatSubmit { job.dispatch(on: queue, queueName: queueName) }
            }
        }
    }
    
    public func schedule(future: @escaping () -> EventLoopFuture<Void>) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler.schedule(schedule: schedule) {
                _ = Services.eventLoop.flatSubmit(future)
            }
        }
    }
    
    public func schedule(task: @escaping () throws -> Void) -> ScheduleBuilder {
        ScheduleBuilder { schedule in
            Services.scheduler.schedule(schedule: schedule, task: task)
        }
    }
}
