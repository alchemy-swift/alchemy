import Echo

extension CodingKey {
    /// The case name of a `CodingKey`. e.g. if the `CodingKey` is defined as `case userID = "user_id"` this
    /// function returns `"userID"`.
    func caseName() -> String? {
        guard let metadata = reflect(Self.self) as? EnumMetadata else {
            return nil
        }

        return withUnsafePointer(to: self) {
            let raw = UnsafeRawPointer($0)
            let tag = Int(metadata.enumVwt.getEnumTag(for: raw))
            return metadata.descriptor.fields.records[tag].name
        }
    }
}
