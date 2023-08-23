import Alchemy

extension Application {
    var loggers: Loggers {
        Loggers(

            /// Your app's default Logger.

            default: "debug",

            // Define your loggers here

            loggers: [
                "debug": .alchemyDefault
            ]
        )
    }
}
