import Foundation

struct EventsPlugin: Plugin {
    func registerServices(in app: Application) {
        app.container.registerSingleton(EventBus())
    }
}
