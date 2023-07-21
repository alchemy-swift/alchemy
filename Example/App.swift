import Alchemy

@main
struct App: Application {
    var commands: [Command.Type] = [Go.self]

    func boot() {
        print("Booting")
    }
}
