import Foundation

/// An HTTP content type. It has a `value: String` appropriate for
/// putting into `Content-Type` headers.
public struct ContentType: Equatable {
    /// Just value of this content type.
    public var value: String
    /// Any parameters to go along with the content type value.
    public var parameters: [String: String] = [:]
    /// The entire string for the Content-Type header.
    public var string: String {
        ([value] + parameters.map { "\($0)=\($1)" }).joined(separator: "; ")
    }
    /// A file extension that matches this content type, if one exists.
    public var fileExtension: String? {
        ContentType.fileExtensionMapping.first { _, value in value == self }?.key
    }
    
    /// Create with a string.
    ///
    /// - Parameter value: The string of the content type.
    public init(_ value: String) {
        let components = value.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        self.value = components.first!
        components[1...]
            .compactMap { (string: String) -> (String, String)? in
                let split = string.components(separatedBy: "=")
                guard let first = split[safe: 0], let second = split[safe: 1] else {
                    return nil
                }
                
                return (first, second)
            }
            .forEach { parameters[$0] = $1 }
    }
    
    /// Creates based off of a known file extension that can be mapped
    /// to an appropriate `Content-Type` header value. Returns nil if
    /// no content type is known.
    ///
    /// The `.` in front of the file extension is optional.
    ///
    /// Usage:
    /// ```swift
    /// let mt = ContentType(fileExtension: "html")!
    /// print(mt.value) // "text/html"
    /// ```
    ///
    /// - Parameter fileExtension: The file extension to look up a
    ///   content type for.
    public init?(fileExtension: String) {
        var noDot = fileExtension
        if noDot.hasPrefix(".") {
            noDot = String(noDot.dropFirst())
        }
        
        guard let type = ContentType.fileExtensionMapping[noDot] else {
            return nil
        }
        
        self = type
    }
    
    // MARK: Common content types
    
    /// image/bmp
    public static let bmp =            ContentType("image/bmp")
    /// text/css
    public static let css =            ContentType("text/css")
    /// text/csv
    public static let csv =            ContentType("text/csv")
    /// application/epub+zip
    public static let epub =           ContentType("application/epub+zip")
    /// application/gzip
    public static let gzip =           ContentType("application/gzip")
    /// image/gif
    public static let gif =            ContentType("image/gif")
    /// text/html
    public static let html =           ContentType("text/html")
    /// text/calendar
    public static let calendar =       ContentType("text/calendar")
    /// image/jpeg
    public static let jpeg =           ContentType("image/jpeg")
    /// text/javascript
    public static let javascript =     ContentType("text/javascript")
    /// application/json
    public static let json =           ContentType("application/json")
    /// audio/midi
    public static let mid =            ContentType("audio/midi")
    /// audio/mpeg
    public static let mp3 =            ContentType("audio/mpeg")
    /// video/mpeg
    public static let mpeg =           ContentType("video/mpeg")
    /// application/octet-stream
    public static let octetStream =    ContentType("application/octet-stream")
    /// audio/ogg
    public static let oga =            ContentType("audio/ogg")
    /// video/ogg
    public static let ogv =            ContentType("video/ogg")
    /// font/otf
    public static let otf =            ContentType("font/otf")
    /// application/pdf
    public static let pdf =            ContentType("application/pdf")
    /// application/x-httpd-php
    public static let php =            ContentType("application/x-httpd-php")
    /// text/plain
    public static let plainText =      ContentType("text/plain")
    /// image/png
    public static let png =            ContentType("image/png")
    /// application/rtf
    public static let rtf =            ContentType("application/rtf")
    /// image/svg+xml
    public static let svg =            ContentType("image/svg+xml")
    /// application/x-tar
    public static let tar =            ContentType("application/x-tar")
    /// image/tiff
    public static let tiff =           ContentType("image/tiff")
    /// font/ttf
    public static let ttf =            ContentType("font/ttf")
    /// audio/wav
    public static let wav =            ContentType("audio/wav")
    /// application/xhtml+xml
    public static let xhtml =          ContentType("application/xhtml+xml")
    /// application/xml
    public static let xml =            ContentType("application/xml")
    /// application/zip
    public static let zip =            ContentType("application/zip")
    /// application/x-www-form-urlencoded
    public static let urlForm =     ContentType("application/x-www-form-urlencoded")
    /// multipart/form-data
    public static let multipart =      ContentType("multipart/form-data")
    
    /// multipart/form-data
    public static func multipart(boundary: String) -> ContentType {
        ContentType("multipart/form-data; boundary=\(boundary)")
    }
    
    /// A non exhaustive mapping of file extensions to known content
    /// types.
    private static let fileExtensionMapping = [
        "aac":    ContentType("audio/aac"),
        "abw":    ContentType("application/x-abiword"),
        "arc":    ContentType("application/x-freearc"),
        "avi":    ContentType("video/x-msvideo"),
        "azw":    ContentType("application/vnd.amazon.ebook"),
        "bin":    ContentType("application/octet-stream"),
        "bmp":    ContentType("image/bmp"),
        "bz":     ContentType("application/x-bzip"),
        "bz2":    ContentType("application/x-bzip2"),
        "csh":    ContentType("application/x-csh"),
        "css":    ContentType("text/css"),
        "csv":    ContentType("text/csv"),
        "doc":    ContentType("application/msword"),
        "docx":   ContentType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        "eot":    ContentType("application/vnd.ms-fontobject"),
        "epub":   ContentType("application/epub+zip"),
        "gz":     ContentType("application/gzip"),
        "gif":    ContentType("image/gif"),
        "htm":    ContentType("text/html"),
        "html":   ContentType("text/html"),
        "ico":    ContentType("image/vnd.microsoft.icon"),
        "ics":    ContentType("text/calendar"),
        "jar":    ContentType("application/java-archive"),
        "jpeg":   ContentType("image/jpeg"),
        "jpg":    ContentType("image/jpeg"),
        "js":     ContentType("text/javascript"),
        "json":   ContentType("application/json"),
        "jsonld": ContentType("application/ld+json"),
        "mid" :   ContentType("audio/midi"),
        "midi":   ContentType("audio/midi"),
        "mjs":    ContentType("text/javascript"),
        "mp3":    ContentType("audio/mpeg"),
        "mpeg":   ContentType("video/mpeg"),
        "mpkg":   ContentType("application/vnd.apple.installer+xml"),
        "odp":    ContentType("application/vnd.oasis.opendocument.presentation"),
        "ods":    ContentType("application/vnd.oasis.opendocument.spreadsheet"),
        "odt":    ContentType("application/vnd.oasis.opendocument.text"),
        "oga":    ContentType("audio/ogg"),
        "ogv":    ContentType("video/ogg"),
        "ogx":    ContentType("application/ogg"),
        "opus":   ContentType("audio/opus"),
        "otf":    ContentType("font/otf"),
        "png":    ContentType("image/png"),
        "pdf":    ContentType("application/pdf"),
        "php":    ContentType("application/x-httpd-php"),
        "ppt":    ContentType("application/vnd.ms-powerpoint"),
        "pptx":   ContentType("application/vnd.openxmlformats-officedocument.presentationml.presentation"),
        "rar":    ContentType("application/vnd.rar"),
        "rtf":    ContentType("application/rtf"),
        "sh":     ContentType("application/x-sh"),
        "svg":    ContentType("image/svg+xml"),
        "swf":    ContentType("application/x-shockwave-flash"),
        "tar":    ContentType("application/x-tar"),
        "tif":    ContentType("image/tiff"),
        "tiff":   ContentType("image/tiff"),
        "ts":     ContentType("video/mp2t"),
        "ttf":    ContentType("font/ttf"),
        "txt":    ContentType("text/plain"),
        "vsd":    ContentType("application/vnd.visio"),
        "wav":    ContentType("audio/wav"),
        "weba":   ContentType("audio/webm"),
        "webm":   ContentType("video/webm"),
        "webp":   ContentType("image/webp"),
        "woff":   ContentType("font/woff"),
        "woff2":  ContentType("font/woff2"),
        "xhtml":  ContentType("application/xhtml+xml"),
        "xls":    ContentType("application/vnd.ms-excel"),
        "xlsx":   ContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        "xml":    ContentType("application/xml"),
        "xul":    ContentType("application/vnd.mozilla.xul+xml"),
        "zip":    ContentType("application/zip"),
        "7z":     ContentType("application/x-7z-compressed"),
    ]
    
    // MARK: - Equatable
    
    public static func == (lhs: ContentType, rhs: ContentType) -> Bool {
        lhs.value == rhs.value
    }
}
