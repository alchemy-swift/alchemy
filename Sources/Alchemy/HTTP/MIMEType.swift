import Foundation

/// An HTTP Media Type. It has a `value: String` appropriate for
/// putting into `Content-Type` headers.
public struct MIMEType {
    /// The value of this MIME type, appropriate for `Content-Type`
    /// headers.
    public var value: String
    
    /// Create with a string.
    ///
    /// - Parameter value: The string of the MIME type.
    public init(_ value: String) {
        self.value = value
    }
    
    // MARK: Common MIME types
    
    /// image/bmp
    public static let bmp =         MIMEType("image/bmp")
    /// text/css
    public static let css =         MIMEType("text/css")
    /// text/csv
    public static let csv =         MIMEType("text/csv")
    /// application/epub+zip
    public static let epub =        MIMEType("application/epub+zip")
    /// application/gzip
    public static let gzip =        MIMEType("application/gzip")
    /// image/gif
    public static let gif =         MIMEType("image/gif")
    /// text/html
    public static let html =        MIMEType("text/html")
    /// text/calendar
    public static let calendar =    MIMEType("text/calendar")
    /// image/jpeg
    public static let jpeg =        MIMEType("image/jpeg")
    /// text/javascript
    public static let javascript =  MIMEType("text/javascript")
    /// application/json
    public static let json =        MIMEType("application/json")
    /// audio/midi
    public static let mid =         MIMEType("audio/midi")
    /// audio/mpeg
    public static let mp3 =         MIMEType("audio/mpeg")
    /// video/mpeg
    public static let mpeg =        MIMEType("video/mpeg")
    /// application/octet-stream
    public static let octetStream = MIMEType("application/octet-stream")
    /// audio/ogg
    public static let oga =         MIMEType("audio/ogg")
    /// video/ogg
    public static let ogv =         MIMEType("video/ogg")
    /// font/otf
    public static let otf =         MIMEType("font/otf")
    /// application/pdf
    public static let pdf =         MIMEType("application/pdf")
    /// application/x-httpd-php
    public static let php =         MIMEType("application/x-httpd-php")
    /// text/plain
    public static let plainText =   MIMEType("text/plain")
    /// image/png
    public static let png =         MIMEType("image/png")
    /// application/rtf
    public static let rtf =         MIMEType("application/rtf")
    /// image/svg+xml
    public static let svg =         MIMEType("image/svg+xml")
    /// application/x-tar
    public static let tar =         MIMEType("application/x-tar")
    /// image/tiff
    public static let tiff =        MIMEType("image/tiff")
    /// font/ttf
    public static let ttf =         MIMEType("font/ttf")
    /// audio/wav
    public static let wav =         MIMEType("audio/wav")
    /// application/xhtml+xml
    public static let xhtml =       MIMEType("application/xhtml+xml")
    /// application/xml
    public static let xml =         MIMEType("application/xml")
    /// application/zip
    public static let zip =         MIMEType("application/zip")
    
}

// Map of file extensions
extension MIMEType {
    /// Creates based off of a known file extension that can be mapped
    /// to an appropriate `Content-Type` header value. Returns nil if
    /// no MIME type is known.
    ///
    /// The `.` in front of the file extension is optional.
    ///
    /// Usage:
    /// ```swift
    /// let mt = MediaType(fileExtension: "html")!
    /// print(mt.value) // "text/html"
    /// ```
    ///
    /// - Parameter fileExtension: The file extension to look up a
    ///   MIME type for.
    public init?(fileExtension: String) {
        var noDot = fileExtension
        if noDot.hasPrefix(".") {
            noDot = String(noDot.dropFirst())
        }
        
        guard let type = MIMEType.fileExtensionMapping[noDot] else {
            return nil
        }
        
        self = type
    }
    
    /// A non exhaustive mapping of file extensions to known MIME
    /// types.
    private static let fileExtensionMapping = [
        "aac":    MIMEType("audio/aac"),
        "abw":    MIMEType("application/x-abiword"),
        "arc":    MIMEType("application/x-freearc"),
        "avi":    MIMEType("video/x-msvideo"),
        "azw":    MIMEType("application/vnd.amazon.ebook"),
        "bin":    MIMEType("application/octet-stream"),
        "bmp":    MIMEType("image/bmp"),
        "bz":     MIMEType("application/x-bzip"),
        "bz2":    MIMEType("application/x-bzip2"),
        "csh":    MIMEType("application/x-csh"),
        "css":    MIMEType("text/css"),
        "csv":    MIMEType("text/csv"),
        "doc":    MIMEType("application/msword"),
        "docx":   MIMEType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        "eot":    MIMEType("application/vnd.ms-fontobject"),
        "epub":   MIMEType("application/epub+zip"),
        "gz":     MIMEType("application/gzip"),
        "gif":    MIMEType("image/gif"),
        "htm":    MIMEType("text/html"),
        "html":   MIMEType("text/html"),
        "ico":    MIMEType("image/vnd.microsoft.icon"),
        "ics":    MIMEType("text/calendar"),
        "jar":    MIMEType("application/java-archive"),
        "jpeg":   MIMEType("image/jpeg"),
        "jpg":    MIMEType("image/jpeg"),
        "js":     MIMEType("text/javascript"),
        "json":   MIMEType("application/json"),
        "jsonld": MIMEType("application/ld+json"),
        "mid" :   MIMEType("audio/midi"),
        "midi":   MIMEType("audio/midi"),
        "mjs":    MIMEType("text/javascript"),
        "mp3":    MIMEType("audio/mpeg"),
        "mpeg":   MIMEType("video/mpeg"),
        "mpkg":   MIMEType("application/vnd.apple.installer+xml"),
        "odp":    MIMEType("application/vnd.oasis.opendocument.presentation"),
        "ods":    MIMEType("application/vnd.oasis.opendocument.spreadsheet"),
        "odt":    MIMEType("application/vnd.oasis.opendocument.text"),
        "oga":    MIMEType("audio/ogg"),
        "ogv":    MIMEType("video/ogg"),
        "ogx":    MIMEType("application/ogg"),
        "opus":   MIMEType("audio/opus"),
        "otf":    MIMEType("font/otf"),
        "png":    MIMEType("image/png"),
        "pdf":    MIMEType("application/pdf"),
        "php":    MIMEType("application/x-httpd-php"),
        "ppt":    MIMEType("application/vnd.ms-powerpoint"),
        "pptx":   MIMEType("application/vnd.openxmlformats-officedocument.presentationml.presentation"),
        "rar":    MIMEType("application/vnd.rar"),
        "rtf":    MIMEType("application/rtf"),
        "sh":     MIMEType("application/x-sh"),
        "svg":    MIMEType("image/svg+xml"),
        "swf":    MIMEType("application/x-shockwave-flash"),
        "tar":    MIMEType("application/x-tar"),
        "tif":    MIMEType("image/tiff"),
        "tiff":   MIMEType("image/tiff"),
        "ts":     MIMEType("video/mp2t"),
        "ttf":    MIMEType("font/ttf"),
        "txt":    MIMEType("text/plain"),
        "vsd":    MIMEType("application/vnd.visio"),
        "wav":    MIMEType("audio/wav"),
        "weba":   MIMEType("audio/webm"),
        "webm":   MIMEType("video/webm"),
        "webp":   MIMEType("image/webp"),
        "woff":   MIMEType("font/woff"),
        "woff2":  MIMEType("font/woff2"),
        "xhtml":  MIMEType("application/xhtml+xml"),
        "xls":    MIMEType("application/vnd.ms-excel"),
        "xlsx":   MIMEType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        "xml":    MIMEType("application/xml"),
        "xul":    MIMEType("application/vnd.mozilla.xul+xml"),
        "zip":    MIMEType("application/zip"),
        "7z":     MIMEType("application/x-7z-compressed"),
    ]
}
