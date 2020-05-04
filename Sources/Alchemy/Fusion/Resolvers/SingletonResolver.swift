struct SingletonResolver: FusableResolver {
    let value: Fusable
    func getValue(for identifier: AnyHashable?) throws -> Fusable {
        guard identifier == nil else {
            throw FusionError.registeredServiceResolverMismatch
        }
        
        return self.value
    }
}
