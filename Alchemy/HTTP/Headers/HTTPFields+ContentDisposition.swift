extension HTTPFields {
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
        
        public init(value: Value, name: String? = nil, filename: String? = nil) {
            self.value = value
            self.name = name
            self.filename = filename
        }

        public static func inline(name: String? = nil, filename: String? = nil) -> ContentDisposition {
            self.init(value: .inline, name: name, filename: filename)
        }

        public static func attachment(name: String? = nil, filename: String? = nil) -> ContentDisposition {
            self.init(value: .attachment, name: name, filename: filename)
        }

        public static func formData(name: String? = nil, filename: String? = nil) -> ContentDisposition {
            self.init(value: .formData, name: name, filename: filename)
        }
    }
    
    public var contentDisposition: ContentDisposition? {
        get {
            guard let disposition = self[.contentDisposition] else {
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
                self[.contentDisposition] = value
            } else {
                self[.contentDisposition] = nil
            }
        }
    }
}
