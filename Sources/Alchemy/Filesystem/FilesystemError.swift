public enum FileError: Error {
    case invalidFileUrl
    case urlUnavailable
    case fileDoesntExist
    case filenameAlreadyExists
    case signedUrlNotAvailable
    case contentNotLoaded
}
