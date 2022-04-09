public enum FileError: Error {
    case invalidFileUrl
    case fileDoesntExist
    case filenameAlreadyExists
    case signedUrlNotAvailable
    case contentNotLoaded
}
