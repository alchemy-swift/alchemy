import Foundation

extension FileManager {
    public func createTempFile(_ name: String, contents: String) -> String {
        let dirPath = NSTemporaryDirectory()
        createFile(atPath: dirPath + name, contents: contents.data(using: .utf8))
        return dirPath + name
    }
}
