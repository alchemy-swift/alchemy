extension HTTPHeaders {
    public struct ContentDisposition {
        public struct Value: ExpressibleByStringLiteral {
            public let string: String
            
            public init(stringLiteral value: StringLiteralType) {
                self.string = value
            }
            
            public static let inline: Value = "inline"
            public static let attachment: Value = "attachment"
            public static let formData: Value = "form-data"
        }
        
        public var value: Value
        public var name: String?
        public var filename: String?
    }
    
    public var contentDisposition: ContentDisposition? {
        get {
            guard let disposition = self["Content-Disposition"].first else {
                return nil
            }
            
            let components = disposition.components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            guard let valueString = components.first else {
                return nil
            }
            
            var directives: [String: String] = [:]
            components
                .dropFirst()
                .compactMap { pair -> (String, String)? in
                    let parts = pair.components(separatedBy: "=")
                    guard let key = parts[safe: 0], let value = parts[safe: 1] else {
                        return nil
                    }
                    
                    return (key.trimmingQuotes, value.trimmingQuotes)
                }
                .forEach { directives[$0] = $1 }
            
            let value = ContentDisposition.Value(stringLiteral: valueString)
            return ContentDisposition(value: value, name: directives["name"], filename: directives["filename"])
        }
        set {
            if let disposition = newValue {
                let value = [
                    disposition.value.string,
                    disposition.name.map { "name=\($0)" },
                    disposition.filename.map { "filename=\($0)" },
                ]
                    .compactMap { $0 }
                    .joined(separator: "; ")
                replaceOrAdd(name: "Content-Disposition", value: value)
            } else {
                remove(name: "Content-Disposition")
            }
        }
    }
}
