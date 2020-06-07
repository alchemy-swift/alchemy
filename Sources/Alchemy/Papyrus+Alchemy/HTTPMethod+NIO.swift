import NIOHTTP1
import Papyrus

extension Papyrus.HTTPMethod {
    var nio: NIOHTTP1.HTTPMethod {
        .init(rawValue: self.rawValue)
    }
}
