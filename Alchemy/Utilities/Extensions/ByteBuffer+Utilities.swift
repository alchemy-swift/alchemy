import Foundation

extension ByteBuffer {
    /// Convert the `ByteBuffer` to `Foundation.Data`.
    var data: Data {
        Data(buffer: self)
    }

    /// Convert the `ByteBuffer` to `String`.
    var string: String {
        String(buffer: self)
    }
}
