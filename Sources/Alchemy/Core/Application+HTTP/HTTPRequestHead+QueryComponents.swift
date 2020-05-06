import Foundation
import NIO
import NIOHTTP1

extension HTTPRequestHead {
    public func getQueryItems() -> [URLQueryItem] {
        URLComponents(string: self.uri)?.percentEncodedQueryItems ?? []
    }
}
