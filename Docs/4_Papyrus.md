# Papyrus

- [Installation](#installation)
  * [Server](#server)
  * [Shared Library](#shared-library)
  * [Client](#client)
- [Usage](#usage)
  * [Defining APIs](#defining-apis)
    + [Basics](#basics)
    + [Supported Methods](#supported-methods)
    + [Empty Request or Reponse](#empty-request-or-reponse)
    + [Custom Request Data](#custom-request-data)
      - [URLQuery](#urlquery)
      - [Header](#header)
      - [Path Parameters](#path-parameters)
      - [Body](#body)
      - [Combinations](#combinations)
  * [Requesting APIs](#requesting-apis)
    + [Client, via Alamofire](#client-via-alamofire)
    + [Server, via AsyncHTTPClient](#server-via-asynchttpclient)
  * [Providing APIs](#providing-apis)

Papyrus is a helper library for defining network APIs in Swift.

It leverages `Codable` and Property Wrappers for creating network APIs that are easy to read, easy to consume (on Server or Client) and easy to provide (on Server). When shared between a Swift client and server, it enforces type safety when requesting and handling HTTP requests.

## Installation

### Server

Like [Fusion](2_Fusion.md), Papyrus is included when you `import Alchemy` on the server side.

### Shared Library

If you're sharing code between clients and servers with a Swift library, you can add `Papyrus` as a dependency to that library via SPM.

```swift
// in your Package.swift

dependencies: [
    .package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.1.0"))
    ...
],
targets: [
    .target(name: "MySharedLibrary", dependencies: [
        .product(name: "Papyrus", package: "alchemy"),
    ]),
]
```

### Client

If you want to define or request `Papyrus` APIs on a Swift client (iOS, macOS, etc) you'll add [`PapyrusAlamofire`](https://github.com/alchemy-swift/papyrus-alamofire) as a dependency via SPM. This is a light wrapper around `Papyrus` with support for requesting endpoints with [Alamofire](https://github.com/Alamofire/Alamofire).

Since Xcode manages the `Package.swift` for iOS and macOS targets, you can add `PapyrusAlamofire` as a dependency through `File` -> `Swift Packages` -> `Add Package Dependency` -> paste `https://github.com/alchemy-swift/papyrus-alamofire` -> check `PapyrusAlamofire` to import.

## Usage

Papyrus is used to define, request, and provide HTTP endpoints.

### Defining APIs

#### Basics

A single endpoint is defined with the `Endpoint<Request, Response>` type. 

`Endpoint.Request` represents the data needed to make this request, and `Endpoint.Response` represents the expected return data from this request. Note that `Request` must conform to `EndpointRequest` and `Response` must conform to `Codable`.

Define an `Endpoint` on an enclosing `EndpointGroup` subclass, and wrap it with a property wrapper representing it's HTTP method and path, relative to a base URL.

```swift
class TodosAPI: EndpointGroup {
    @GET("/todos")
    var getAll: Endpoint<GetTodosRequest, [TodoDTO]>

    struct GetTodosRequest: EndpointRequest {
        @URLQuery
        var limit: Int

        @URLQuery
        var incompleteOnly: Bool
    }

    struct TodoDTO: Codable {
        var name: String
        var isComplete: Bool
    }
}
```

Notice a few things about the `getAll` endpoint. 

1. The `@GET("/todos")` indicates that the endpoint is at `POST {some_base_url}/todos`. 
2. The endpoint expects a request object of `GetUsersRequest` which conforms to `EndpointRequest` and contains two properties, wrapped by `@URLQuery`. The `URLQuery` wrappers indicate data that's expected in the query url of the request. This lets requesters of this endpoint know that the endpoint needs two query values, `limit` and `incompleteOnly`. It also lets the providers of this endpoint know that incoming requests to `GET /todo` will contain two items in their query URLs; `limit` and `incompleteOnly`.
3. The endpoint has a response type of `[TodoDTO]`, defined below it. This lets clients know what response type to expect and lets providers know what response type to return.

This gives anyone reading or using the API all the information they would need to interact with it.

Requesting this endpoint might look like
```
GET {some_base_url}/todos?limit=1&incompleteOnly=0 
```
While a response would look like
```json
[
    {
        "name": "Do laundry",
        "isComplete": false
    },
    {
        "name": "Learn Alchemy",
        "isComplete": true
    },
    {
        "name": "Be awesome",
        "isComplete": true
    },
]
```

**Note**: The DTO suffix of `TodoDTO` stands for `Data Transfer Object`, indicating that this type represents some data moving across the wire. It is not necesssary, but helps differentiate from local `Todo` model types that may exist on either client or server.

#### Supported Methods

Out of the box, Papyrus provides `@GET`, `@POST`, `@PUT`, `@PATCH`, `@DELETE` as well as a `@CUSTOM("OPTIONS", "/some/path")` that can take any method string for defining your `Endpoint`s.

#### Empty Request or Reponse

If you're endpoint doesn't have any request or response data that needs to be parsed, you may define the `Request` or `Response` type to be `Empty`.

```swift
class SomeAPI: EndpointGroup {
    @GET("/foo")
    var noRequest: Endpoint<Empty, SomeResponse>

    @POST("/bar")
    var noResponse: Endpoint<SomeRequest, Empty>
}
```

#### Custom Request Data

Like `@URLQuery`, there are other property wrappers to define where on an HTTP request data should be. 

Each wrapper denotes a value in the request at the proper location with a key of the name of the property. For example `@Header var someHeader: String` indicates requests to this endpoint should have a header named `someHeader`.

**Note**: `@Body` ignore's its property name and instead encodes it's value into the entire request body.

##### URLQuery

`@URLQuery` can wrap a `Bool`, `String`, `String?`, `Int`, `Int?` or `[String]`. 

Optional properties with nil values will be omitted.

```swift
class SomeAPI: EndpointGroup {
    // There will be a query1, query3 and optional query2 in the request URL.
    @GET("/foo")
    var queryRequest: Endpoint<QueryRequest, Empty>
}

struct QueryRequest: EndpointRequest {
    @URLQuery var query1: String
    @URLQuery var query2: String?
    @URLQuery var query3: Int
}
```

##### Header

`@Header` can wrap a `String`. It indicates that there should be a header of name `{propertyName}` on the request.

```swift
class SomeAPI: EndpointGroup {
    @POST("/foo")
    var foo: Endpoint<HeaderRequest, Empty>
}

/// Defines a header "someHeader" on the request.
struct HeaderRequest: EndpointRequest {
    @Header var someHeader: String
}
```

##### Path Parameters

`@Path` can wrap a `String`. It indicates a dynamic path parameter at `:{propertyName}` in the request path.

```swift
class SomeAPI: EndpointGroup {
    @POST("/some/:someID/value")
    var foo: Endpoint<PathRequest, Empty>
}

struct PathRequest: EndpointRequest {
    @Path var someID: String
}
```

##### Body

`@Body` can wrap any `Codable` type which will be encoded to the request. By default, the body is encoded as JSON, but you may override `EndpointRequest.contentType` to use another encoding type.

```swift
class SomeAPI: EndpointGroup {
    @POST("/json")
    var json: Endpoint<JSONBody, Empty>

    @GET("/url")
    var json: Endpoint<URLEncodedBody, Empty>
}

/// Will encode `BodyData` in the request body.
struct JSONBody: EndpointRequest {
    @Body var body: BodyData
}

/// Will encode `BodyData` in the request URL.
struct URLEncodedBody: EndpointRequest {
    static let contentType = .urlEncoded

    @Body var body: BodyData
}

struct BodyData: Codable {
    var foo: String
    var baz: Int
}
```

##### Combinations

You can combine any number of these property wrappers, except for `@Body`. There can only be a single `@Body` per request.

```swift
struct MyCustomRequest: EndpointRequest {
    struct SomeCodable: Codable {
        ...
    }

    @Body var bodyData: SomeCodable

    @Header var someHeader: String

    @Path var userID: String

    @URLQuery var query1: Int
    @URLQuery var query2: String
    @URLQuery var query3: String?
    @URLQuery var query3: [String]
}
```

### Requesting APIs

Papyrus can be used to request endpoints on client or server targets.

To request an endpoint, create the `EndpointGroup` with a `baseURL` and call `request` on a specific endpoint, providing the needed `Request` type.

Requesting the the `TodosAPI.getAll` endpoint from above looks similar on both client and server.

```swift
// `import PapyrusAlamofire` on client
import Alchemy

let todosAPI = TodosAPI(baseURL: "http://localhost:8888")
todosAPI.getAll
    .request(.init(limit: 50, incompleteOnly: true)) { response, todoResult in
        switch todoResult {
        case .success(let todos):
            for todo in todos {
                print("Got todo: \(todo.name)")
            }
        case .failure(let error):
            print("Got error: \(error).")
        }
    }
```

This would make a request that looks like:
```
GET http://localhost:8888/todos?limit=50&incompleteOnly=false
```

While the APIs are built to look similar, the client and server implementations sit on top of different HTTP libraries and are customizable in separate ways.

#### Client, via Alamofire

Requesting an `Endpoint` client side is built on top of [Alamofire](https://github.com/Alamofire/Alamofire). By default, requests are run on `Session.default`, but you may provide a custom `Session` for any customization, interceptors, etc.

#### Server, via AsyncHTTPClient

Request an `Endpoint` in an `Alchemy` server is built on top of [AsyncHTTPClient](https://github.com/swift-server/async-http-client). By default, requests are run on `Services.client`, but you may provide a custom `HTTPClient`.

### Providing APIs

Alchemy contains convenient extensions for registering your `Endpoint`s on a `Router`. Use `.on` to register an `Endpoint` to a router.

```swift
let todos = TodosAPI()
router.on(todos.getAll) { (request: Request, data: GetTodosRequest) in
    // when a request to `GET /todos` is handled, the `GetTodosRequest` properties will be loaded from the `Alchemy.Request`.
}
```

This will automatically parse the relevant `GetTodosRequest` data from the right places (URL query, headers, body, path parameters) on the incoming request. In this case, "limit" & "incompleteOnly" from the request query `String`. 

If expected data is missing, a `400` is thrown describing the missing expected fields:

```json
400 Bad Request
{
    "message": "expected query value `limit`"
}
```

**Note**: Currently, only `ContentType.json` is supported for decoding request `@Body`s.

_Next page: [Database: Basics](5a_DatabaseBasics.md)_

_[Table of Contents](/Docs#docs)_
