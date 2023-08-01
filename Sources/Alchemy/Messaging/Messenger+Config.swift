struct MessengerPlugin: Plugin {
    // TODO: How to do this with a generic in Messenger?

//    public let messengers: [MessengerIdentifier: Messenger<C>]

//    init(messengers: [MessengerIdentifier : Messenger<C>]) {
//        self.messengers = messengers
//    }

    func registerServices(in container: Container) {
//        for (id, messenger) in messengers {
//            container.registerSingleton(messenger, id: id)
//        }
    }
}
