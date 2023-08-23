import Alchemy

@main
struct App: Application {
    func boot() {
        post("user") {
            try await DB.table("users").insert($0.content)
        }

        get("success") { _ in

        }

        get("bad") { _ -> String in
            throw HTTPError(.badRequest)
        }

        get("fail") { _ -> String in
            throw HTTPError(.internalServerError)
        }
    }
}
