/// A month of the year.
public enum Month: Int, ExpressibleByIntegerLiteral {
    /// January
    case jan = 1
    /// February
    case feb = 2
    /// March
    case mar = 3
    /// April
    case apr = 4
    /// May
    case may = 5
    /// June
    case jun = 6
    /// July
    case jul = 7
    /// August
    case aug = 8
    /// September
    case sep = 9
    /// October
    case oct = 10
    /// November
    case nov = 11
    /// December
    case dec = 12
    
    public init(integerLiteral value: Int) {
        self = Month(rawValue: value) ?? .jan
    }
}
