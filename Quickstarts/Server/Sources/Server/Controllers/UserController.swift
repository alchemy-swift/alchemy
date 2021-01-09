import Alchemy

struct UsersController: Controller {
    func route(_ router: Router) {
        router
            // Get the current user
            .on(.GET, at: "/user") {
                try $0.get(User.self)
            }
            // Logout the current user by deleting their token
            .on(.GET, at: "/logout") {
                try $0.get(UserToken.self).delete()
            }
    }
}
