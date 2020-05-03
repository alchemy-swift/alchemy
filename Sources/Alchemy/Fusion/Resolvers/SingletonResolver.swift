struct SingletonResolver: FusableResolver {
    let value: Fusable
    func getValue(for identifier: String?) throws -> Fusable {
        guard identifier == nil else {
            throw FusionError.registeredServiceResolverMismatch
        }
        
        return self.value
    }
}
