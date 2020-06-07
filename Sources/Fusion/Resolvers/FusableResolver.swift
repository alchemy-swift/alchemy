protocol FusableResolver {
    func getValue(for identifier: AnyHashable?) throws -> Fusable
}

extension FusableResolver {
    func getTypedValue<T: Fusable>(for identifier: AnyHashable?) throws -> T {
        guard let typedValue = try self.getValue(for: identifier) as? T else {
            throw FusionError.registeredServiceTypeMismatch
        }
        
        return typedValue
    }
}
