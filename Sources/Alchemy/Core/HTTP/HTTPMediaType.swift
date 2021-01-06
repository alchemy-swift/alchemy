import Foundation

/// An HTTP Media Type (MIME type). It has a `value: String` appropriate for putting into
/// `Content-Type` headers.
public struct MediaType {
    /// The value of this media type, appropriate for `Content-Type` headers.
    public var value: String
    
    /// Create with a string.
    ///
    /// - Parameter value: The string of the Media Type (MIME type) appropriate for `Content-Type`
    ///                    headers.
    public init(_ value: String) {
        self.value = value
    }
}

// Map of file extensions
extension MediaType {
    /// Creates based off of a known file extension that can be mapped to an appropriate Media Type
    /// header value. Returns nil if no Media Type is known.
    ///
    /// The `.` in front of the file extension is optional.
    ///
    /// Usage:
    /// ```
    /// let mt = MediaType(fileExtension: "html")!
    /// print(mt.value) // "text/html"
    /// ```
    ///
    /// - Parameter fileExtension: The file extension to look up a Media Type for.
    public init?(fileExtension: String) {
        var noDot = fileExtension
        if noDot.hasPrefix(".") {
            noDot = String(noDot.dropFirst())
        }
        
        guard let type = MediaType.fileExtensionMapping[noDot] else {
            return nil
        }
        
        self = type
    }
    
    /// A non exhaustive mapping of file extensions to known media types.
    private static let fileExtensionMapping = [
        "aac":    MediaType("audio/aac"),
        "abw":    MediaType("application/x-abiword"),
        "arc":    MediaType("application/x-freearc"),
        "avi":    MediaType("video/x-msvideo"),
        "azw":    MediaType("application/vnd.amazon.ebook"),
        "bin":    MediaType("application/octet-stream"),
        "bmp":    MediaType("image/bmp"),
        "bz":     MediaType("application/x-bzip"),
        "bz2":    MediaType("application/x-bzip2"),
        "csh":    MediaType("application/x-csh"),
        "css":    MediaType("text/css"),
        "csv":    MediaType("text/csv"),
        "doc":    MediaType("application/msword"),
        "docx":   MediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        "eot":    MediaType("application/vnd.ms-fontobject"),
        "epub":   MediaType("application/epub+zip"),
        "gz":     MediaType("application/gzip"),
        "gif":    MediaType("image/gif"),
        "htm":    MediaType("text/html"),
        "html":   MediaType("text/html"),
        "ico":    MediaType("image/vnd.microsoft.icon"),
        "ics":    MediaType("text/calendar"),
        "jar":    MediaType("application/java-archive"),
        "jpeg":   MediaType("image/jpeg"),
        "jpg":    MediaType("image/jpeg"),
        "js":     MediaType("text/javascript"),
        "json":   MediaType("application/json"),
        "jsonld": MediaType("application/ld+json"),
        "mid" :   MediaType("audio/midi"),
        "midi":   MediaType("audio/midi"),
        "mjs":    MediaType("text/javascript"),
        "mp3":    MediaType("audio/mpeg"),
        "mpeg":   MediaType("video/mpeg"),
        "mpkg":   MediaType("application/vnd.apple.installer+xml"),
        "odp":    MediaType("application/vnd.oasis.opendocument.presentation"),
        "ods":    MediaType("application/vnd.oasis.opendocument.spreadsheet"),
        "odt":    MediaType("application/vnd.oasis.opendocument.text"),
        "oga":    MediaType("audio/ogg"),
        "ogv":    MediaType("video/ogg"),
        "ogx":    MediaType("application/ogg"),
        "opus":   MediaType("audio/opus"),
        "otf":    MediaType("font/otf"),
        "png":    MediaType("image/png"),
        "pdf":    MediaType("application/pdf"),
        "php":    MediaType("application/x-httpd-php"),
        "ppt":    MediaType("application/vnd.ms-powerpoint"),
        "pptx":   MediaType("application/vnd.openxmlformats-officedocument.presentationml.presentation"),
        "rar":    MediaType("application/vnd.rar"),
        "rtf":    MediaType("application/rtf"),
        "sh":     MediaType("application/x-sh"),
        "svg":    MediaType("image/svg+xml"),
        "swf":    MediaType("application/x-shockwave-flash"),
        "tar":    MediaType("application/x-tar"),
        "tif":    MediaType("image/tiff"),
        "tiff":   MediaType("image/tiff"),
        "ts":     MediaType("video/mp2t"),
        "ttf":    MediaType("font/ttf"),
        "txt":    MediaType("text/plain"),
        "vsd":    MediaType("application/vnd.visio"),
        "wav":    MediaType("audio/wav"),
        "weba":   MediaType("audio/webm"),
        "webm":   MediaType("video/webm"),
        "webp":   MediaType("image/webp"),
        "woff":   MediaType("font/woff"),
        "woff2":  MediaType("font/woff2"),
        "xhtml":  MediaType("application/xhtml+xml"),
        "xls":    MediaType("application/vnd.ms-excel"),
        "xlsx":   MediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        "xml":    MediaType("application/xml"),
        "xul":    MediaType("application/vnd.mozilla.xul+xml"),
        "zip":    MediaType("application/zip"),
        "7z":     MediaType("application/x-7z-compressed"),
    ]
}
