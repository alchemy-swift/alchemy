import Alchemy
import Papyrus

@Application
struct App {

    @GET("/200")
    func success() {
        //
    }

    @GET("/400")
    func badRequest() throws {
        throw HTTPError(.badRequest)
    }

    @GET("/500")
    func internalServerError() async throws {
        throw HTTPError(.internalServerError)
    }

    @GET("/job")
    func job() async throws {
        try await App.$expensive(one: "", two: 1)
    }

    @Job 
    static func expensive(one: String, two: Int) async throws {
        print("Hello")
    }
}
