import Alchemy

@main
struct App: Application {
    func boot() {
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
    }
}
