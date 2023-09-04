<p align="center"><a href="https://www.alchemyswift.com/"><img src="https://user-images.githubusercontent.com/6025554/132588005-5f8a6a94-ec15-4cab-9be9-1e90e86d374f.png" width="400"></a></p>

<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.5-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/alchemy.svg" alt="License"></a>
</p>

> **Fully `async/await`!**

Welcome to Alchemy, an elegant, batteries included backend framework for Swift. You can use it to build a production ready backend for your next mobile app, cloud project or website.

```swift
@main
struct App: Application {
    func boot() {
        get("/") { req in
            "Hello World!"
        }
    }
}
```

## About

Alchemy provides you with Swifty APIs for everything you need to build production-ready backends. It makes writing your backend in Swift a breeze by easing typical tasks, such as:

-   [Simple, fast routing engine](https://www.alchemyswift.com/essentials/routing).
-   [Powerful, dependency injection container](https://www.alchemyswift.com/getting-started/services).
-   Expressive, Swifty [database ORM](https://www.alchemyswift.com/rune-orm/rune).
-   Database agnostic [query builder](https://www.alchemyswift.com/database/query-builder) and [schema migrations](https://www.alchemyswift.com/database/migrations).
-   [Robust job queues backed by Redis or SQL](https://www.alchemyswift.com/digging-deeper/queues).
-   [Cron-like task & job Scheduler](https://www.alchemyswift.com/digging-deeper/scheduling).

### Why Alchemy?

Swift on the server is exciting but also relatively nascant ecosystem. Building a backend with it can be daunting and the pains of building in a new ecosystem can get in the way.

The goal of Alchemy is to provide a robust, batteries included framework with everything you need to build production ready backends. Stay focused on building your next amazing project in modern, Swifty style without sweating the details.

### Guiding principles

**1. Batteries Included**

With Routing, an ORM, advanced Redis & SQL support, Authentication, Queues, Cron, Caching, HTTP and much more, `import Alchemy` gives you all the pieces you need to start building a production grade server app.

**2. Convention over Configuration**

APIs focus on simple syntax with lots of baked in convention so you can build much more with less code. This doesn't mean you can't customize; there's always an escape hatch to configure things your own way.

**3. Rapid Development**

Alchemy is designed to help you take apps from idea to implementation as swiftly as possible.

**4. Interoperability**

Alchemy is built on top of the lightweight, [blazingly](https://web-frameworks-benchmark.netlify.app/result?l=swift) fast [Hummingbird](https://github.com/hummingbird-project/hummingbird-core) framework. It is fully compatible with existing `swift-nio` and `vapor` components like [stripe-kit](https://github.com/vapor-community/stripe-kit), [soto](https://github.com/soto-project/soto) or [jwt-kit](https://github.com/vapor/jwt-kit) so that you can easily integrate with all existing Swift on the Server work.

**5. Keep it Swifty**

Swift is built to write concice, safe and elegant code. Alchemy leverages it's best parts to help you write great code faster and obviate entire classes of backend bugs. It's API is completely `async/await` meaning you have access to all Swift's cutting edge concurrency features.

## Get Started

To get started check out the extensive docs starting with [Setup](https://www.alchemyswift.com/getting-started/setup).

## Contributing

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so feel free to dive in and contribute features, bug fixes, docs or tune ups.

You can also report bugs, suggest features, or just say hi on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) and [Discord](https://discord.gg/74Bq29q22u).

##

👋 Thanks for checking out Alchemy!
