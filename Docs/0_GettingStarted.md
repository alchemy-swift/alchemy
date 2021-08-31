# Getting Started

- [Installation](#installation)
  * [CLI](#cli)
  * [Swift Package Manager](#swift-package-manager)
- [Start Coding](#start-coding)

## Installation

### CLI

The Alchemy CLI is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
mint install alchemy-swift/alchemy-cli
```

Creating an app with the CLI will let you pick between a backend or fullstack (`iOS` frontend, `Alchemy` backend, `Shared` library) project. 

1. `alchemy new MyNewProject`
2. `cd MyNewProject` (if you selected fullstack, `MyNewProject/Backend`)
3. `swift run`
4. view your brand new app at http://localhost:3000

### Swift Package Manager

Alchemy is also installable through the [Swift Package Manager](https://github.com/apple/swift-package-manager).

```swift
dependencies: [
    .package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.2.0"))
    ...
],
targets: [
    .target(name: "MyServer", dependencies: [
        .product(name: "Alchemy", package: "alchemy"),
    ]),
]
```

From here, conform to `Application` somewhere in your target and add the `@main` attribute.

```swift
@main
struct App: Application {
    func boot() {
        get("/") { _ in
            return "Hello from alchemy!"
        }
    }
}
```

Run your app with `swift run` and visit `localhost:3000` in the browser to see your new server in action.

## Start Coding!

Congrats, you're off to the races! Check out the rest of the guides for what you can do with Alchemy.

_Up next: [Architecture](1_Configuration.md)_

_[Table of Contents](/Docs#docs)_
