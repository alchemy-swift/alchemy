import Foundation
import EchoMirror
import EchoProperties
import Echo

/// A `Codable` type that also defines a mapping of some of it's stored `KeyPath`s to their corresponding
/// `CodingKey`.
protocol KeyPathCodable: Codable {
    /// A mapping of `PartialKeyPath<Self>` to the `CodingKey` it represents (and the string that will be used
    /// during database queries).
    static var mapping: [(PartialKeyPath<Self>, CodingKey)] { get }
    // ^ Should probably be a dict, but compiler complained
}

extension KeyPathCodable {
    static var mapping: [(PartialKeyPath<Self>, CodingKey)] {
        /// 1. Using reflection, find all stored KeyPath's & their names of this type.
        /// 2. Using a dummy decoder, find all top level `CodingKey`s on this object.
        /// 3. Match the name of the `KeyPath` to the `caseName` of each CodingKey.
        []
    }
}

/// Example of manual conformance to `KeyPathCodable`.
private struct SomeJSON: KeyPathCodable {
    static var mapping: [(PartialKeyPath<SomeJSON>, CodingKey)] = [
        (\SomeJSON.value, CodingKeys.value),
        (\SomeJSON.other, CodingKeys.other),
    ]
    
    let value: String
    let other: Int
}
