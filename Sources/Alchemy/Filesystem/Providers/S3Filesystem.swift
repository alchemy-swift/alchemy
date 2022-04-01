import NIOCore
import SotoS3

struct S3Filesystem: FilesystemProvider {
    /// The file IO helper for streaming files.
    private let s3: S3
    /// Used for allocating buffers when pulling out file data.
    private let bufferAllocator = ByteBufferAllocator()
    
    var root: String { bucket }
    let bucket: String
    
    // MARK: - FilesystemProvider
    
    init(key: String, secret: String, bucket: String, region: Region) {
        let client = AWSClient(
            credentialProvider: .static(accessKeyId: key, secretAccessKey: secret),
            httpClientProvider: .createNewWithEventLoopGroup(Loop.group)
        )
        
        self.s3 = S3(client: client, region: region)
        self.bucket = bucket
    }
    
    func get(_ filepath: String) async throws -> File {
        let req = S3.GetObjectRequest(bucket: bucket, key: filepath)
        let res = try await s3.getObject(req)
        let size = Int(res.contentLength ?? 0)
        return File(name: filepath, size: size, content: res.body?.asByteBuffer().map { .buffer($0) } ?? .data(Data()))
    }
    
    func create(_ filepath: String, content: ByteContent) async throws -> File {
        let req = S3.PutObjectRequest(acl: .private, body: .byteBuffer(content.buffer), bucket: bucket, key: filepath)
        _ = try await s3.putObject(req)
        return File(name: filepath, size: content.buffer.writerIndex, content: content)
    }
    
    func exists(_ filepath: String) async throws -> Bool {
        let req = S3.GetObjectRequest(bucket: bucket, key: filepath)
        do {
            _ = try await s3.getObject(req)
            return true
        } catch {
            return false
        }
    }
    
    func delete(_ filepath: String) async throws {
        let req = S3.DeleteObjectRequest(bucket: bucket, key: filepath)
        _ = try await s3.deleteObject(req)
    }
}
