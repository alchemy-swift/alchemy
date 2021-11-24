/// A day of the week.
public enum DayOfWeek: Int, ExpressibleByIntegerLiteral {
    /// Sunday
    case sun = 0
    /// Monday
    case mon = 1
    /// Tuesday
    case tue = 2
    /// Wednesday
    case wed = 3
    /// Thursday
    case thu = 4
    /// Friday
    case fri = 5
    /// Saturday
    case sat = 6
    
    public init(integerLiteral value: Int) {
        self = DayOfWeek(rawValue: value) ?? .sun
    }
}
