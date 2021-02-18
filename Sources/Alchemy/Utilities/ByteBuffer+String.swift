import NIO

extension ByteBuffer {
    var string: String? {
        var copy = self
        return copy.readString(length: self.writerIndex)
    }
}
