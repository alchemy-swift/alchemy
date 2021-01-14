/// An `EndpointGroup` represents a collection of endpoints from the
/// same host.
///
/// The `baseURL` represents the shared base URL of all endpoints in
/// this group. An `Endpoint` must be defined as a property of an
/// `EndpointGroup` in order to properly inherit its `baseURL`.
///
/// Usage:
/// ```swift
/// final class UsersService: EndpointGroup {
///     @POST("/users")
///     var createUser: Endpoint<CreateUserRequest, UserDTO>
///
///     @GET("/users/:userID")
///     var getUser: Endpoint<GetUserRequest, UserDTO>
///
///     @GET("/users/friends")
///     var getFriends: Endpoint<Empty, [UserDTO]>
/// }
///
/// let users = UsersService(baseURL: "https://api.my-app.com")
///
/// // The baseURL of this request is inferred to be
/// // `https://api.my-app.com`
/// users.createUser.request(CreateUserRequest(...))
///     ... // platform specific code for handling the response of
///         // type `UserDTO`
/// ```
///
/// In this example, all the endpoints above will be requested from
/// the baseURL of the `UsersService` isntance, in this case
/// `https://api.my-app.com`.
///
/// Ensure that all defined `Endpoint`s are properties of an
/// `EndpointGroup` type so that their `baseURL` can be
/// automatically inferred when they are requested.
open class EndpointGroup {
    /// The base URL for all `Endpoint`s defined in this group.
    public let baseURL: String
    
    /// Initialize a group with a base url.
    ///
    /// - Parameter baseURL: The `baseURL` for all `Endpoint`s
    ///   defined in this group.
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
}
