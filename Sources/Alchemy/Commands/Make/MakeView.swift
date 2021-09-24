import ArgumentParser

struct MakeView: Command {
    static var logStartAndFinish: Bool = false
    static var configuration = CommandConfiguration(
        commandName: "make:view",
        discussion: "Create a new Plot view"
    )
    
    @Argument var name: String
    
    func start() -> EventLoopFuture<Void> {
        catchError {
            try FileCreator.shared.create(fileName: name, contents: viewTemplate(), in: "Views")
            return .new()
        }
    }
    
    private func viewTemplate() -> String {
        return """
        import Alchemy

        struct \(name): HTMLView {
            let greetings: [String]
            let name: String?
            
            var content: HTML {
                HTML(
                    .head(
                        .title("My website"),
                        // Be sure to use a `StaticFileMiddleware` on your app
                        // so that related resources (css, js, images, etc)
                        // can be loaded by the browser.
                        .stylesheet("styles/home.css"),
                        // You can add raw javascript...
                        .script("console.log('Hello from `HomeView`!')"),
                        // ... or import a .js file.
                        .script(.src("js/home.js"))
                    ),
                    .body(
                        .div(
                            .h1("My website"),
                            // Add an <li> for each greeting.
                            .ul(.forEach(self.greetings) {
                                .li(.class("greeting"), .text($0))
                            }),
                            // If name isn't nil, add a <p>.
                            .unwrap(self.name) {
                                .p("Welcome, \\($0)!")
                            }
                        )
                    )
                )
            }
        }
        """
    }
}
