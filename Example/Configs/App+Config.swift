import Alchemy

extension App {

    /// Configurations related to your app.

    var configuration: Configuration {
        Configuration(

            // Define plugins your app uses here.

            plugins: [
                //
            ],

            // Define any custom commands here.

            commands: [
                Go.self
            ]
        )
    }
}
