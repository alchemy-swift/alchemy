import Alchemy

struct HomeView: HTMLView {
    let title: String
    let favoriteAnimals: [String]

    var content: HTML {
        HTML(
            .head(
                .title(self.title),
                .stylesheet("styles.css")
            ),
            .body(
                .div(
                    .h1(.class("title"), "My favorite animals are"),
                    .ul(.forEach(self.favoriteAnimals) {
                        .li(.class("name"), .text($0))
                    })
                )
            )
        )
    }
}
