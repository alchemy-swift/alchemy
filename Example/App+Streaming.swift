import Alchemy

struct Foo: Codable {
    var bar: String = "baz"
}

struct Bar: Codable {
    var foo: String = "foo"
}

extension Dictionary: ResponseConvertible where Key == String, Value == Encodable {
    public func response() async throws -> Response {
        fatalError()
    }
}

extension Array: ResponseConvertible where Element == Encodable {
    public func response() async throws -> Response {
        fatalError()
    }
}

extension App {
    /*
     Stream cases
     1. Generic streaming
       i.   server incoming request
       ii.  server outgoing response
       iii. client outgoing request
       iv.  client incoming response
       
     2. File streaming
       i.   server incoming files (assume multipart, get each file)
       ii.  server outgoing files (just attach, for multiple zip into directory)
       iii. client outgoing files (turn into multipart)
       iv.  client incoming files (assume content-disposition header)
     */
    func streaming() {
        post("/say_hello") { req in
            "Hello, \(req.query("name")!)!"
        }
        
        get("/download") { req in
            try await Http.get("https://example.com/image.jpg")
        }
        
        get("/xml") { req -> Response in
            let xmlData = """
                    <note>
                        <to>Rachel</to>
                        <from>Josh</from>
                        <heading>Message</heading>
                        <body>Hello from XML!</body>
                    </note>
                    """.data(using: .utf8)!
            return Response(
                status: .accepted,
                headers: ["Content-Type": "application/xml"],
                body: .data(xmlData)
            )
        }
        
        get("/dict") { _ in
            return [
                "wit": 1,
                "wat": Foo(),
                "wut": Bar(),
            ]
        }
        
        get("/array") { _ in
            return [Foo(), Bar()]
        }
        
        // MARK: - Server Incoming
        
        post("/upload_files") { _ in
            try await Http.execute()
        }
        
        // MARK: - Server Outgoing
        
        get("/download_file") { _ in
            try await Storage.get("resources/large_file.dmg")
        }
        
        get("/download_image") { _ -> Response in
            try await Storage.get("resources/large_image.jpg").download()
        }
        
        get("/hello") { _ in "Hello!" }
    }
}
