struct IdentifiedSingletonResolver: FusableResolver {
    private(set) var values: [String: Fusable]
    
    init(values: [String: Fusable]) {
        self.values = values
    }
    
    func getValue(for identifier: String?) throws -> Fusable {
        guard let identifier = identifier else {
            throw FusionError.expectedIdentifier
        }
        
        guard let value = self.values[identifier] else {
            throw FusionError.identifierNotRegistered
        }
        
        return value
    }
    
    func adding(service: Fusable, for identifier: String) -> IdentifiedSingletonResolver {
        var copy = self
        copy.values[identifier] = service
        return copy
    }
}
