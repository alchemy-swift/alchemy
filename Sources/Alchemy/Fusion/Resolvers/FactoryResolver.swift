struct FactoryResolver: FusableResolver {
    let factory: () throws -> Fusable
    
    func getValue(for identifier: String?) throws -> Fusable {
        guard identifier == nil else {
            throw FusionError.registeredServiceResolverMismatch
        }
        
        return try self.factory()
    }
}
