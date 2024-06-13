public enum ContentError: Error {
    case unknownContentType(ContentType?)
    case emptyBody
    case cantFlatten
    case notDictionary
    case notArray
    case doesntExist
    case wasNull
    case typeMismatch
    case notSupported(String)
    case misc(Error)
}
