import Alchemy

extension Application {

    /// Configurations related to your app's loggers.

    var loggers: Loggers {
        Loggers(

            /// Your app's default Logger.

            default: {
                if Env.isXcode {
                    .xcode
                } else if Env.isTesting {
                    .null
                } else if Env.isDebug {
                    .debug
                } else {
                    .stdout
                }
            }(),

            // Define your loggers here

            loggers: [
                .debug: .debug,
                .null: .null,
                .stdout: .stdout,
                .xcode: .xcode,
            ]
        )
    }
}

extension Logger.Identifier {
    static let debug: Logger.Identifier = "debug"
    static let null: Logger.Identifier = "null"
    static let stdout: Logger.Identifier = "stdout"
    static let xcode: Logger.Identifier = "xcode"
}
