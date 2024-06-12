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

    @Job
    static func expensive() async throws {
        print("Hello")
    }
}
