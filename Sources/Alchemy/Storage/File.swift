/// Represents a file with a name and binary contents.
public struct File: Equatable {
    // The name of the file, including the extension.
    public let name: String
    // The binary contents of the file.
    public let contents: ByteBuffer
}

extension File {
    func store(in: StorageProvider) {
        
    }
}
