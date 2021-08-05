<p><img src="https://user-images.githubusercontent.com/6025554/104392567-3226f000-54f7-11eb-9ad6-b8795764aace.png" width="400"></a></p>

<p>Elegant, batteries included web framework for Swift.</p>

<p>
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.4-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/alchemy.svg" alt="License"></a>
</p>

```swift
@main
struct App: Application {
    func boot() {
        get("/hello") {
            "Hello World!"
        }
    }
}
```

## Features

- Fast, trie based routing.
- Customizable middleware.
- First class support for [Plot](https://github.com/JohnSundell/Plot), a typesafe HTML DSL.
- Expressive ORM and query builder with out of the box support for Postgres and MySQL.
- Database agnostic schema migrations.
- Cron-like job scheduling.
- Powerful dependency injection.
- Typesafe API definitions, sharable between Swift clients & server.
- Concise, elegant APIs built with the best parts of Swift.
- Extensive [docs](Docs#docs).

## Installation

### Quickstart

The Alchemy CLI can help you get started. It is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
mint install alchemy-swift/cli@main
```

```shell
alchemy new MyNewProject
```

You'll be guided through picking a new project template, either `Backend` or `Fullstack`.

### Swift Package Manager

Alchemy is also installable through the [Swift Package Manager](https://github.com/apple/swift-package-manager). Until `1.0.0` is released, minor version changes might be breaking, so you may want to use `upToNextMinor`.

```swift
dependencies: [
    .package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.1.0"))
    ...
],
targets: [
    .target(name: "MySwiftBackend", dependencies: [
        .product(name: "Alchemy", package: "alchemy"),
    ]),
]
```

### Running It

You can run your server from Xcode or with

```shell
swift run
```

Check out the [deployment guide](Docs/9_Deploying.md) for deploying to Linux or Docker.

## Documentation

### [Docs](Docs#docs)

The Docs provide a step by step walkthrough of everything Alchemy has to offer. They also touch on essential core backend concepts for developers new to server side development.

**Note**: If something is confusing or difficult to understand please let us know on [Discord](https://discord.gg/Rz6kWQTFn9)!

### [API Reference](https://github.com/alchemy-swift/alchemy/wiki)

The inline comments are extensive and full of examples. You can check them out in the codebase or on the [Github wiki](https://github.com/alchemy-swift/alchemy/wiki).

## Why Alchemy?

Alchemy is designed to make your development experience...

- **Smooth**. Elegant syntax, heavy documentation, and extensive guides touching on every feature. Alchemy is designed to help you build backends faster, not get in the way.
- **Simple**. Context-switch less by writing full stack Swift. Keep the codebase simple with all your iOS, backend, and shared code in a single Xcode workspace.
- **Rapid**. Quickly develop full stack features, end to end. Write less code by using supporting libraries ([Papyrus](Docs/4_Papyrus.md), [Fusion](Docs/2_Fusion.md)) to share code & provide type safety between your backend & Swift clients.
- **Safe**. Swift is built for safety. Its typing, optionals, value semantics and error handling are leveraged throughout Alchemy to help protect you against thread safety issues, nil values and unexpected program state.
- **Swifty**. Concise, expressive APIs built with the best parts of Swift.

## Roadmap

Our top priorities right now are:

0. Conversion of async APIs from `EventLoopFuture` to [async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) as soon as it's released.
1. Filling in missing core server pieces. Particularly,
    - `HTTP/2` support
    - `SSL`/`TLS` support
    - Built in support for `multipart/form-data` & `application/x-www-form-urlencoded`
2. Persistent, queued jobs backed by Redis / Memcached.

## Contributing

- Ask **questions** on Stack Overflow with the tag [`alchemy-swift`](https://stackoverflow.com/questions/tagged/alchemy-swift). You can also ask us in [Discord](https://discord.gg/Rz6kWQTFn9).
- Report **bugs** as an [issue on Github](https://github.com/alchemy-swift/alchemy/issues/new) (bonus points if it's with a failing test case) or [Discord](https://discord.gg/mWzHgHqYFA).
- Submit **feature requests** on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) or bring them up on [Discord](https://discord.gg/74Bq29q22u).

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so don't be afraid to dive in and submit PRs for bug fixes, documentation cleanup, forks or tune ups!
