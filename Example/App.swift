import Alchemy

@main
struct App: Application {
    func boot() {
        useAll(LoggingMiddleware())

        post("user") {
            print("SUP \($0.content)")
//            DB.table("users").insert($0.content)
        }
    }
}

struct LoggingMiddleware: Middleware {
    func intercept(_ request: Request, next: (Request) async throws -> Response) async throws -> Response {
        let start = Date()
        do {
            let response = try await next(request)
            let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
            Log.info("\(response.status.code) \(request.method.rawValue) \(request.path) \(elapsedTime)")
            return response
        } catch {
            if let error = error as? HTTPError {
                let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
                Log.info("\(error.status.code) \(request.method.rawValue) \(request.path) \(elapsedTime)")
            } else {
                let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
                Log.info("\(request.method.rawValue) \(request.path) \(elapsedTime)")
            }

            throw error
        }
    }
}
