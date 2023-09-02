import Alchemy

@main
struct App: Application {
    func boot() {
        get("/stream", options: .stream) { req in
            Response {
                try await $0.write("foo")
                try await $0.write("bar")
                try await $0.write("baz")
            }
        }

        post("user") {
            try await DB.table("users").insert($0.content)
        }

        get("success") { _ in

        }

        get("bad") { _ -> Void in
            throw HTTPError(.badRequest)
        }

        get("fail") { _ -> Void in
            throw HTTPError(.internalServerError)
        }

        get("shutdown") { _ in
            Task {
                try await stop()
            }
        }
    }

    func schedule(on schedule: Scheduler) {
        schedule.job(GoJob())
            .everySecond()
    }
}

struct GoJob: Job, Codable {
    func handle(context: JobContext) async throws {
        Log.warning("Hello from GoJob!")
    }
}
