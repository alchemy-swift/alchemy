import Foundation
import Rainbow

/// Used to generate files related to an alchemy project.
struct FileCreator {
    static var shared = FileCreator(rootPath: "Sources/App/")
    
    /// The root path where files should be created, relative to the apps
    /// working directory.
    let rootPath: String
    
    func create(fileName: String, extension: String = "swift", contents: String, in directory: String, comment: String? = nil) throws {
        let migrationLocation = try folderPath(for: directory)

        let filePath = "\(migrationLocation)/\(fileName).\(`extension`)"
        let destinationURL = URL(fileURLWithPath: filePath)
        try contents.write(to: destinationURL, atomically: true, encoding: .utf8)
        Log.comment("🧪 create \(filePath.green)")
        if let comment = comment {
            Log.comment("          └─ \(comment)")
        }
    }

    func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: rootPath + path)
    }
    
    private func folderPath(for name: String) throws -> String {
        let folder = rootPath + name
        guard FileManager.default.fileExists(atPath: folder) else {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: folder), withIntermediateDirectories: true)
            return folder
        }
        
        return folder
    }
    
    static func mock() {
        shared = FileCreator(rootPath: NSTemporaryDirectory())
    }
}

