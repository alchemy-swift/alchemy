import Alchemy

struct 4330CB2B-C6DD-4527-B23B-B097ECF79E0E: HTMLView {
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
                        .p("Welcome, \($0)!")
                    }
                )
            )
        )
    }
}