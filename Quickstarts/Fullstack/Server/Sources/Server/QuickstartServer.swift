import Alchemy
import Shared

struct QuickstartServer: Application {
    @Inject var router: HTTPRouter
    
    func setup() {
        print(SharedStruct.text)
    }
}
