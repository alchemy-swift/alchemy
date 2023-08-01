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

/*

 Goal: Simple, Declarative Configs that can be used by Alchemy and Other Plugins

 1. `Configurable` & `Configured` protocol.
 2. default variables for the implementor to override.
 3. configurations in the plugin initializer.

 */
