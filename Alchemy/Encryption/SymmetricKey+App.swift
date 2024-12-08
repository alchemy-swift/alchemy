import Crypto
import Foundation

extension SymmetricKey {
    public static var app: SymmetricKey {
        print("env: \(Env.runtimeOverrides) \(Env.appKey)")
        guard let appKey = Env.appKey else {
            preconditionFailure("Unable to load APP_KEY from Environment. Please set APP_KEY before encrypting any data with `Crypt` or provide a custom `SymmetricKey` using `Crypt(key:)`.")
        }

        guard let data = Data(base64Encoded: appKey) else {
            preconditionFailure("Unable to create encryption key from APP_KEY. Please ensure APP_KEY is a base64 encoded String.")
        }

        return SymmetricKey(data: data)
    }
}

extension Environment {
    @Env public var appKey: String?
}
