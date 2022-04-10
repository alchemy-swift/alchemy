import NIOCore
import SotoS3

extension Filesystem {
    /// Create a filesystem backed by an s3 bucket.
    public static func s3(key: String, secret: String, bucket: String, root: String = "", region: Region, endpoint: String? = nil) -> Filesystem {
        Filesystem(provider: S3Filesystem(key: key, secret: secret, bucket: bucket, root: root, region: region, endpoint: endpoint))
    }
}

struct S3Filesystem: FilesystemProvider {
    /// The file IO helper for streaming files.
    private let s3: S3
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
    var root: String
    let bucket: String
    
    // MARK: - FilesystemProvider
    
    init(key: String, secret: String, bucket: String, root: String, region: Region, endpoint: String? = nil) {
        let client = AWSClient(
            credentialProvider: .static(accessKeyId: key, secretAccessKey: secret),
            httpClientProvider: .createNewWithEventLoopGroup(Loop.group)
        )
        
        self.s3 = S3(client: client, region: region, endpoint: endpoint)
        self.bucket = bucket
        self.root = root
    }
    
    func get(_ filepath: String) async throws -> File {
        let path = resolvedPath(filepath)
        let req = S3.GetObjectRequest(bucket: bucket, key: path)
        let res = try await s3.getObject(req)
        let size = Int(res.contentLength ?? 0)
        let content: ByteContent? = res.body?.asByteBuffer().map { .buffer($0) }
        return File(name: path, source: .filesystem(path: path), content: content, size: size)
    }
    
    func create(_ filepath: String, content: ByteContent) async throws -> File {
        let path = resolvedPath(filepath)
        let req = S3.PutObjectRequest(acl: .private, body: .byteBuffer(content.buffer), bucket: bucket, key: path)
        _ = try await s3.putObject(req)
        return File(name: path, source: .filesystem(path: path))
    }
    
    func exists(_ filepath: String) async throws -> Bool {
        do {
            let path = resolvedPath(filepath)
            let req = S3.HeadObjectRequest(bucket: bucket, key: path)
            _ = try await s3.headObject(req)
            return true
        } catch {
            return false
        }
    }
    
    func delete(_ filepath: String) async throws {
        let path = resolvedPath(filepath)
        let req = S3.DeleteObjectRequest(bucket: bucket, key: path)
        _ = try await s3.deleteObject(req)
    }
    
    func url(_ filepath: String) throws -> URL {
        let path = resolvedPath(filepath)
        guard let url = URL(string: "\(s3.endpoint)/\(path)") else {
            throw FileError.urlUnavailable
        }
        
        return url
    }
    
    func temporaryURL(_ filepath: String, expires: TimeAmount, headers: HTTPHeaders = [:]) async throws -> URL {
        let path = resolvedPath(filepath)
        guard let url = URL(string: "https://\(bucket).\(s3.region.rawValue).\(s3.endpoint)/\(path)") else {
            throw FileError.urlUnavailable
        }
        
        return try await s3.signURL(url: url, httpMethod: .GET, headers: headers, expires: .seconds(10))
    }
    
    func directory(_ filePath: String) -> FilesystemProvider {
        var copy = self
        if root.isEmpty {
            copy.root.append(filePath)
        } else {
            let path = root.last == "/" ? filePath : "/\(filePath)"
            copy.root.append(path)
        }
        
        return copy
    }
    
    private func resolvedPath(_ filePath: String) -> String {
        let path = root.last == "/" ? filePath : "/\(filePath)"
        return root + path
    }
}
