// Better way to do these?
extension ByteBuffer {
    var data: Data { Data(buffer: self) }
    var string: String { String(buffer: self) }
}
