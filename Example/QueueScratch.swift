import Alchemy

struct DoExpensiveWork: Job, Codable {
    func run() async throws {
        print("SUP")
    }
}

/*
 
 1. An instance, type, or at the very least closure needs to be registered with the app to call code from a worker.
 2.

 */


/*

 OPTION 1: A type that literally just gets encoded / decoded

 PRO: Simple to understand what's going on.
 CON: A bit distant from a function.
 CON: Everything must be codable.

 */

struct SendMailJob {
    let subject: String
    let message: String
    let recipients: [String]
    let bcc: [String]

//    func handle(context: QueueContext) {
//
//    }

//    static func register(app: Application) {
//        app.registerJob(SendMail.self)
//    }

//    static func dispatch() {
//        try await SendMail(subject: "foo", message: "bar", recipients: [], bcc: []).dispatch()
//    }
}
