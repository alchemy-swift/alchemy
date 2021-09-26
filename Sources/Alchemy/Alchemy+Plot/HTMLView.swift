import Foundation

/// A protocol for defining HTML views to return to a client.
///
/// Usage:
/// ```swift
/// struct HomeView: HTMLView {
///     let title: String
///     let favoriteAnimals: [String]
///
///     var content: HTML {
///         HTML(
///             .head(
///                 .title(self.title),
///                 .stylesheet("styles.css")
///             ),
///             .body(
///                 .div(
///                     .h1("My favorite animals are"),
///                     .ul(.forEach(self.favoriteAnimals) {
///                         .li(.class("name"), .text($0))
///                     })
///                 )
///             )
///         )
///     }
/// }
///
/// router.route(.GET) {
///     HomeView(
///         title: "My Website",
///         favoriteAnimals: ["Platypus", "Tapir", "Lemur"]
///     )
/// }
/// ```
public protocol HTMLView: ResponseConvertible {
    /// The HTML content of this view.
    var content: HTML { get }
}

extension HTMLView {
    // MARK: ResponseConvertible
    
    public func convert() -> Response {
        let body = HTTPBody(text: content.render(), mimeType: .html)
        return Response(status: .ok, body: body)
    }
}
