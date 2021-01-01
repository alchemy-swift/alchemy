# 🧪 Alchemy

![Swift](https://img.shields.io/badge/Swift-5.3-orange.svg)
![MIT](https://img.shields.io/github/license/joshuawright11/alchemy.svg)
![release](https://img.shields.io/github/release/joshuawright11/alchemy.svg)

Alchemy is a Swift web framework for building backends. It makes your development experience...

- **Swifty**. Concise, expressive APIs built with the best parts of Swift.
- **Safe**. Swift is built for safety. It's typing, optionals, value semantics and error handling are leveraged throughout Alchemy to help protect you against thread safety issues, nil values and unexpected program state.
- **Rapid**. Write less code & rapidly develop full stack features, end to end. The CLI & supporting libraries (Papyrus, Fusion) are built around facilitating shared code & providing type safety between your server & iOS clients.
- **Easy**. With elegant syntax, 100% documentation, and guides touching on nearly every feature, Alchemy is designed to help you build backends faster, not get in the way.
- **Simple**. Juggle less Xcode projects by keeping your full stack Swift code in a monorepo containing your iOS app, Alchemy Server & Shared code. The CLI will help you get started.

## Getting Started

### CLI

The Alchemy CLI is created to kickstart and accelerate development. We recommend using this to get your project going.

Download it with [Homebrew](https://brew.sh).
```shell
brew install alchemy
```
And create a new project. This will walk you through choosing a starter project.
```shell
alchemy new
```

### Manually

If you prefer not to use the CLI, you can clone a sample project full of example code from the [Quickstart directory](https://github.com/joshuawright11/alchemy/tree/main/Quickstart).

If you'd rather start with an empty slate, you can create a new Xcode project (likely a package) and add alchemy to the `Package.swift` file.
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

### Adding `Papyrus` or `Fusion` to non-server targets
Papyrus (network interfaces) and Fusion (dependency injection) are built to work on both server and client (iOS, macOS, etc).

For server targets, they're included when you `import Alchemy`. For installation on client & shared targets, check out the [Fusion](Documentation/1b_ArchitectureServices.md) and [Papyrus](Documentation/3_Papyrus.md) guides.

## Documentation

### [Guides](Documentation/0_GettingStarted.md)
Reading the guides is the recommended way of getting up to speed. They provide a step by step walkthrough of just about everything Alchemy has to offer as well as essential core backend concepts for developers new to server side development.

**Note**: These guides are made to be followed by both people with backend experience and iOS devs with little to no backend experience. If something is confusing or difficult to understand please let us know on [Discord](https://discord.gg/Dnhh4yJe)!

### [API Reference](https://github.com/joshuawright11/alchemy/wiki)
The inline comments are extensive and full of examples. You can check it out in the codebase or a generated version on the [Github wiki](https://github.com/joshuawright11/alchemy/wiki).

### [Quickstart Code](https://github.com/joshuawright11/alchemy/tree/main/Quickstart)
If you'd rather just jump into reading some code, the projects in `Quickstart/` are contrived apps for the purpose of showing working, documented examples of everything Alchemy can do. You can clone them with `$ alchemy new` or browse through their code.

## Roadmap

Our top priorities right now are:

0. Conversion of async APIs from `EventLoopFuture` to [async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) as soon as it's released.
1. Filling in missing core server pieces. Particularly,
    - `HTTP/2` support
    - `SSL`/`TLS` support
    - Sending static files (html, css, js, images)
    - Built in support for `multipart/form-data` & `application/x-www-form-urlencoded`
2. A guide around deployment to various services.
3. Interfaces around Redis / Memcached.
4. A Swifty templating solution for sending back dynamic HTML pages.

## Contributing

- Ask **questions** on Stack Overflow with the tag `alchemy-swift`. You can also ask us in [Discord](https://discord.gg/Dnhh4yJe).
- Report **bugs** as an [issue on Github](https://github.com/joshuawright11/alchemy/issues/new) (ideally with a failing test case) or [Discord](https://discord.gg/CDZWAda3).
- Submit **feature requests** as an [issue on Github](https://github.com/joshuawright11/alchemy/issues/new) or bring them up on [Discord](https://discord.gg/9CZ4ksvn).

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to documentation, so don't be afraid to dive in and submit PRs for bug fixes, documentation cleanup, forks or tune ups.
