import NIOHTTP1
import Papyrus

extension HTTPReqMethod {
    var nio: HTTPMethod {
        .init(rawValue: self.rawValue)
    }
}
