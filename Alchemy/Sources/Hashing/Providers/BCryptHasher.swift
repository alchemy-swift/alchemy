import Foundation
import HummingbirdBcrypt

extension HashAlgorithm where Self == BCryptHasher {
    public static var bcrypt: BCryptHasher {
        BCryptHasher(rounds: 10)
    }
    
    public static func bcrypt(rounds: Int) -> BCryptHasher {
        BCryptHasher(rounds: rounds)
    }
}

public final class BCryptHasher: HashAlgorithm {
    private let rounds: UInt8

    public init(rounds: Int) {
        self.rounds = UInt8(rounds)
    }
    
    public func verify(_ plaintext: String, hash: String) -> Bool {
        Bcrypt.verify(plaintext, hash: hash)
    }
    
    public func make(_ value: String) -> String {
        Bcrypt.hash(value, cost: rounds)
    }
}
