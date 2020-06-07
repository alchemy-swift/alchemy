import Papyrus

/// WIP: Something that can be encoded to and decoded from an HTTP request
///
/// Should probably be moved to `SwiftAPI` repo.
//public protocol RequestCodable {}

/// Request validations
/// (Handle through typed Middleware):
/// 1. Router level: validate pre-conditions (auth, headers, app version)
///
/// (Handle with Request.validate(expectedType)):
/// 2. Controller level: validate expected input (params unique to the request)

/// Validation
/// ----------
/// Validate a type from a request, automatically loading the correct info from the right places, denoted by
/// property wrappers.
///
/// i.e.
/// ```
/// struct FriendCreateRequest: Codable {
///     @Path  var friendID: String
///     @Query var friendNickname: String
/// }
/// ```
/// Would attempt to load a `friendID` from the path, and a `friendNickname` from the url query. Failure to
/// find a field in it's denoted spot results in an error.
///
/// Could also potentially conform the type to `Validatable` and force some non-type validation, i.e. password
/// is 8+ chars and has a number, uppercased char, etc.
public extension HTTPRequest {
    func validate<T: RequestCodable>(_ type: T.Type) throws -> T {
        fatalError()
    }
}
