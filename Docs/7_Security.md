# Security

- [Bcrypt](#bcrypt)
- [Request Auth](#request-auth)
  * [Authorization: Basic](#authorization-basic)
  * [Authorization: Bearer](#authorization-bearer)
  * [Authorization: Either](#authorization-either)
- [Auth Middleware](#auth-middleware)
  * [Basic Auth Middleware](#basic-auth-middleware)
  * [Token Auth Middleware](#token-auth-middleware)

Alchemy provides built in support for Bcrypt hashing and automatic authentication via Rune & `Middleware`.

## Bcrypt

Standard practice is to never store plain text passwords in your database. Bcrypt is a password hashing function that creates a one way hash of a plaintext password. It's an expensive process CPU-wise, so it will help protect your passwords from being easily cracked through brute forcing.

It's simple to use.

```swift
let hashedPassword = Bcrypt.hash("password")
let isPasswordValid = Bcrypt.verify("password", hashedPassword) // true
```

Because it's expensive, you may want to run this off of an `EventLoop` thread. For convenience, there's an API for that. This will run Bcrypt on a separate thread and complete back on the initiating `EventLoop`.

```swift
Bcrypt.hashAsync("password")
    .whenSuccess { hashedPassword in
        // do something with the hashed password
    }

Bcrypt.verifyAsync("password", hashedPassword)
    .whenSuccess { isMatch in
        print("Was a match? \(isMatch).")
    }
```

## Request Auth

`Request` makes it easy to pull `Authorization` information off an incoming request. 

### Authorization: Basic

You can access `Basic` auth info via `.basicAuth() -> HTTPAuth.Basic?`.

```swift
let request: Request = ...
if let basic = request.basicAuth() {
    print("Got basic auth. Username: \(basic.username) Password: \(basic.password)")
}
```

### Authorization: Bearer

You can also get `Bearer` auth info via `.bearerAuth() -> HTTPAuth.Bearer?`.

```swift
let request: Request = ...
if let bearer = request.bearerAuth() {
    print("Got bearer auth with Token: \(bearer.token)")
}
```

### Authorization: Either

You can also get any `Basic` or `Bearer` auth from the request.

```swift
let request: Request = ...
if let auth = request.getAuth() {
    switch auth {
    case .bearer(let bearer):
        print("Request had Basic auth!")
    case .basic(let basic):
        print("Request had Basic auth!")
    }
}
```

## Auth Middleware

Incoming `Request` can be automatically authorized against your Rune `Model`s by conforming your `Model`s to "authable" protocols and protecting routes with the generated `Middleware`.

### Basic Auth Middleware

To authenticate via the `Authorization: Basic ...` headers on incoming `Request`s, conform your Rune `Model` that stores usernames and password hashes to `BasicAuthable`.

```swift
struct User: Model, BasicAuthable {
    var id: Int?
    let username: String
    let password: String
}
```

Now, put `User.basicAuthMiddleware()` in front of any endpoints that need basic auth. When the request comes in, the `Middleware` will compare the username and password in the `Authorization: Basic ...` headers to the username and password hash of the `User` model. If the credentials are valid, the `Middleware` will set the relevant `User` instance on the `Request`, which can then be accessed via `request.get(User.self)`.

If the credentials aren't valid, or there is no `Authorization: Basic ...` header, the Middleware will throw an `HTTPError(.unauthorized)`.

```swift
app.use(User.basicAuthMiddleware())
app.get("/login") { req in
    let authedUser = try req.get(User.self)
    // Do something with the authorized user...
}
```

Note that Rune is inferring a username at column `"email"` and password at column `"password"` when verifying credentials. You may set custom columns by overriding the `usernameKeyString` or `passwordKeyString` of your `Model`.

```swift
struct User: Model, BasicAuthable {
    static let usernameKeyString = "username"
    static let passwordKeyString = "hashed_password"

    var id: Int?
    let username: String
    let hashedPassword: String
}
```

### Token Auth Middleware

Similarly, to authenticate via the `Authorization: Bearer ...` headers on incoming `Request`s, conform your Rune `Model` that stores access token values to `TokenAuthable`. Note that this time, you'll need to specify a `BelongsTo` relationship to the User type this token authorizes.

```swift
struct UserToken: Model, BasicAuthable {
    var id: Int?
    let value: String

    @BelongsTo var user: User
}
```

Like with `Basic` auth, put the `UserToken.tokenAuthMiddleware()` in front of endpoints that are protected by bearer authorization. The `Middleware` will automatically parse out tokens from incoming `Request`s and validate them via the `UserToken` type. If the token matches a `UserToken` row, the related `User` and `UserToken` will be `.set()` on the `Request` for access in a handler.

```swift
router.middleWare(UserToken.tokenAuthMiddleware())
    .on(.GET, at: "/todos") { req in
        let authedUser = try req.get(User.self)
        let theToken = try req.get(UserToken.self)
    }
```

Note that Rune is again inferring a `"value"` column on the `UserToken` to which it will compare the tokens on incoming `Request`s. This can be customized by overriding the `valueKeyString` property of your `Model`.

```swift
struct UserToken: Model, BasicAuthable {
    static let valueKeyString = "token_string"
    
    var id: Int?
    let tokenString: String

    @BelongsTo var user: User
}
```

_Next page: [Queues](8_Queues.md)_

_[Table of Contents](/Docs#docs)_
