@testable import Alchemy
import XCTest

final class PlotTests: XCTestCase {
    func testHTMLView() {
        let home = HomeView(title: "Welcome", favoriteAnimals: ["Kiwi", "Dolphin"])
        let res = home.convert()
        XCTAssertEqual(res.status, .ok)
        XCTAssertEqual(res.body?.contentType, .html)
        XCTAssertEqual(res.body?.decodeString(), home.content.render())
    }
    
    func testHTMLConversion() {
        let html = HomeView(title: "Welcome", favoriteAnimals: ["Kiwi", "Dolphin"]).content
        let res = html.convert()
        XCTAssertEqual(res.status, .ok)
        XCTAssertEqual(res.body?.contentType, .html)
        XCTAssertEqual(res.body?.decodeString(), html.render())
    }
    
    func testXMLConversion() {
        let xml = XML(.attribute(named: "attribute"), .element(named: "element"))
        let res = xml.convert()
        XCTAssertEqual(res.status, .ok)
        XCTAssertEqual(res.body?.contentType, .xml)
        XCTAssertEqual(res.body?.decodeString(), xml.render())
    }
}

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
                    .h1("My favorite animals are"),
                    .ul(.forEach(self.favoriteAnimals) {
                        .li(.class("name"), .text($0))
                    })
                )
            )
        )
    }
}