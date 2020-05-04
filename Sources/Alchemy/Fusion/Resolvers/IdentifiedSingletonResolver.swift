struct IdentifiedSingletonResolver: FusableResolver {
    private(set) var values: [AnyHashable: Fusable]
    
    init(values: [AnyHashable: Fusable]) {
        self.values = values
    }
    
    func getValue(for identifier: AnyHashable?) throws -> Fusable {
        guard let identifier = identifier else {
            throw FusionError.expectedIdentifier
        }
        
        guard let value = self.values[identifier] else {
            throw FusionError.identifierNotRegistered
        }
        
        return value
    }
    
    func adding(service: Fusable, for identifier: AnyHashable) -> IdentifiedSingletonResolver {
        var copy = self
        copy.values[identifier] = service
        return copy
    }
}
