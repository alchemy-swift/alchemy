import Alchemy

struct HomeView: HTMLView {
    let greetings: [String]
    let name: String?
    
    var content: HTML {
        HTML(
            .head(
                .title("My website"),
                .stylesheet("styles/home.css"),
                .script("js/home.js")
            ),
            .body(
                .div(
                    .h1("My website"),
                    .ul(.forEach(self.greetings) {
                        .li(.class("greeting"), .text($0))
                    }),
                    .unwrap(self.name) {
                        .p("Welcome, \($0)!")
                    }
                )
            )
        )
    }
}
