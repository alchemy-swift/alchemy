# Getting Started

## Installation

### Via the Alchemy CLI

We recommend using the Alchemy CLI to get your project going.

Download it with [Homebrew](https://brew.sh).
```shell
brew install alchemy
```
And create a new project.
```shell
alchemy new MyProject
```
You'll be offered a few templates for your new project. All of these will be cloned from the `Quickstart/` directory;

#### Server + Shared + iOS App

A single Xcode project with an Alchemy server, iOS app, and shared package. The shared package is already imported by both the server & app so you'll be ready to share code between your server and app.

#### Server + Shared Package

This creates two packages, an Alchemy server & a package the server depends on. Useful for integrating into existing iOS projects, just drag and drop into the existing Xcode project, and have your iOS app depend on the shared package.

**Note**: for the packages to load, you'll likely need to close and re-open your project after dragging and dropping in the server & shared packages.

#### Server only

A single package that's just an Alchemy server.

### Manually

If you prefer not to use the CLI, you can clone a sample project full of example code from the [Quickstart directory](Quickstart/).

If you'd rather start with an empty slate, create a new Xcode package and add Alchemy to the `Package.swift` file.
```swift
dependencies: [
    .package(url: "https://github.com/joshuawright11/alchemy", .branch("master"))
    ...
],
targets: [
    .target(name: "MySwiftServer", dependencies: [
        .product(name: "Alchemy", package: "alchemy"),
    ]),
]
```

## Run it!
If you cloned one of the quickstart projects, run the `QuickstartServer` target and you should see something like

```
Server started and listening on [IPv6]::1/::1:8888
```

Otherwise, add a file called `MyApplication.swift` with the following:

```swift
import Alchemy

struct MyApplication: Application {
    @Inject router: Router

    func setup() {
        self.router.on(.get, at: "/hello") { request in
            "Hello, World!"
        }
    }
}
```

Then add a `main.swift` with...

```swift
Launch<MyApplication>.main()
```
Run your server, make a GET request to `localhost:8888/hello` and you should get `"Hello, World!"` as the response.

## Start Coding!
Congrats, you're off to the races! Check out the rest of the guides for what you can do with Alchemy.

_Up next: [Architecture](1a_Architecture.md)_

_[Table of Contents](/Docs)_