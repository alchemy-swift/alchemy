# Getting Started

- [Installation](#installation)
  * [Quickstart](#quickstart)
  * [Swift Package Manager](#swift-package-manager)
- [Run It](#run-it)
- [Start Coding](#start-coding)

## Installation

### Quickstart

The Alchemy CLI can help you get started with one of the [Quickstart](../Quickstarts/) templates. It is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
brew install mint
```

```shell
mint install alchemy-swift/cli@main
```

```shell
alchemy new MyAwesomeProject
```

You'll be guided through picking a new project template, either `Backend` or `Fullstack`. You can check out the details of each one in the [Quickstarts README](../Quickstarts/)

### Swift Package Manager

Alchemy is also installable through the [Swift Package Manager](https://github.com/apple/swift-package-manager).

```swift
dependencies: [
    .package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.1.0"))
    ...
],
targets: [
    .target(name: "MySwiftServer", dependencies: [
        .product(name: "Alchemy", package: "alchemy"),
    ]),
]
```

## Run it!

If you cloned one of the quickstart projects, run the `Backend` scheme in Xcode and you should see something like...

```
[Server] started and listening on [IPv6]::1/::1:8888.
```

You can also run it via command line.

```bash
swift run
```

If you created a project from scratch via SPM, add a file called `MyApplication.swift` with the following:

```swift
import Alchemy

struct MyApplication: Application {
    func boot() {
        self.get("/hello") { request in
            "Hello, World!"
        }
    }
}
```

Then add a `main.swift` with...

```swift
MyApplication.launch()
```
Run your server, make a GET request to `localhost:8888/hello` and you should get `"Hello, World!"` as the response.

## Start Coding!

Congrats, you're off to the races! Check out the rest of the guides for what you can do with Alchemy.

_Up next: [Architecture](1a_Architecture.md)_

_[Table of Contents](/Docs#docs)_
