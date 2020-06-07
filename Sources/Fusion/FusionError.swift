enum FusionError: Error {
    case containerDeallocated
    case serviceAlreadyRegistered
    case identifierAlreadyRegistered
    case serviceNotRegistered
    case registeredServiceTypeMismatch
    case registeredServiceResolverMismatch
    case expectedIdentifier
    case identifierNotRegistered
}
