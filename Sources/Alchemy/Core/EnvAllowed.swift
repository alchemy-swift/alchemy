public protocol EnvAllowed {
    static func from(_ value: String) -> Self
}

extension String: EnvAllowed {
    public static func from(_ value: String) -> String {
        value
    }
}

extension Int: EnvAllowed {
    public static func from(_ value: String) -> Int {
        guard let intVal = Int(value) else {
            fatalError("Unable to convert env value of \(value) to an 'Int'.")
        }
        
        return intVal
    }
}

extension Double: EnvAllowed {
    public static func from(_ value: String) -> Double {
        guard let doubleVal = Double(value) else {
            fatalError("Unable to convert env value of \(value) to a 'Double'.")
        }
        
        return doubleVal
    }
}

extension Bool: EnvAllowed {
    public static func from(_ value: String) -> Bool {
        guard let boolVal = Bool(value) else {
            fatalError("Unable to convert env value of \(value) to a 'Bool'.")
        }
        
        return boolVal
    }
}
