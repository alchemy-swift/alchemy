// Better way to do these?
extension ByteBuffer {
    func data() -> Data? {
        var copy = self
        return copy.readData(length: writerIndex)
    }
    
    func string() -> String? {
        var copy = self
        return copy.readString(length: writerIndex)
    }
}
