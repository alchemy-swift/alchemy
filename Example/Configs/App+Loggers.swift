import Alchemy

extension Application {

    /// Configurations related to your app's loggers.

    var loggers: Loggers {
        Loggers(

            /// Your app's default Logger.

            default: {
                if Env.isDebug {
                    "debug"
                } else if Env.isTesting {
                    "null"
                } else if Env.isXcode {
                    "xcode"
                } else {
                    "stdout"
                }
            }(),

            // Define your loggers here

            loggers: [
                "debug": .debug,
                "null": .null,
                "stdout": .stdout,
                "xcode": .xcode,
            ]
        )
    }
}
