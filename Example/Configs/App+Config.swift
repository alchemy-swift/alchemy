import Alchemy

extension App {
    var configuration: Configuration {
        Configuration(

            // Define plugins your app uses here.

            plugins: [
                .databases,
                .filesystems,
                .queues,
            ],

            // Define any custom commands here.

            commands: [
                Go.self
            ]
        )
    }
}
