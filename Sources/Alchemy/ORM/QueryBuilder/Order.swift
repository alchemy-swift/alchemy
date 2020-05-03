import Foundation

public struct Order {

    public enum Sort: String {
        case ascending = "asc"
        case descending = "desc"
    }

    let column: String
    let direction: Sort
}
