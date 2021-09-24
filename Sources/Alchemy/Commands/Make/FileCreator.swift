import Foundation
import Rainbow
import SwiftCLI

struct FileCreator {
    static let shared = FileCreator()
    
    func create(fileName: String, contents: String, in directory: String, comment: String? = nil) throws {
        let migrationLocation = try folderPath(for: directory)

        let filePath = "\(migrationLocation)/\(fileName).swift"
        let destinationURL = URL(fileURLWithPath: filePath)
        try contents.write(to: destinationURL, atomically: true, encoding: .utf8)
        print("🧪 create \(filePath.green)")
        if let comment = comment {
            print("          └─ \(comment)")
        }
    }
    
    private func folderPath(for name: String) throws -> String {
        let locations = try Task.capture(bash: "find Sources/App -type d -name '\(name)'").stdout.split(separator: "\n")
        if let folder = locations.first {
            return String(folder)
        } else {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: "Sources/App/\(name)"), withIntermediateDirectories: true)
            return "Sources/App/\(name)"
        }
    }
}
