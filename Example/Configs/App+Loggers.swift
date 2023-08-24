import Alchemy

extension Application {

    /// Configurations related to your app's loggers.

    var loggers: Loggers {
        Loggers(

            /// Your app's default Logger.

            default: {
                if Env.isXcode {
                    "xcode"
                } else if Env.isTesting {
                    "null"
                } else if Env.isDebug {
                    "debug"
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
