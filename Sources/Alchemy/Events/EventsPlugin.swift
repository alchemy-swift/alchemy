import Foundation

struct EventsPlugin: Plugin {
    func registerServices(in container: Container) {
        container.registerSingleton(EventBus())
    }
}
