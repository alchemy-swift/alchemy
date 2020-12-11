import Alchemy

struct QuickstartServer: Application {
    @Inject var router: HTTPRouter
    
    func setup() {
        print("Hello world")
    }
}
