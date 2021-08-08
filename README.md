<p align="center"><img src="https://user-images.githubusercontent.com/6025554/104392567-3226f000-54f7-11eb-9ad6-b8795764aace.png" width="400"></a></p>

<p align="center">
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.4-orange.svg" alt="Swift Version"></a>
<a href="https://github.com/alchemy-swift/alchemy/releases"><img src="https://img.shields.io/github/release/alchemy-swift/alchemy.svg" alt="Latest Release"></a>
<a href="https://github.com/alchemy-swift/alchemy/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alchemy-swift/alchemy.svg" alt="License"></a>
</p>

Welcome to Alchemy, an elegant, batteries included backend framework for Swift. You can use it to build a production ready backend for your next mobile app, cloud project or website.

```swift
@main 
struct App: Application {
    func boot() {
        get("/hello") { req in
            "Hello World!"
        }
    }
}
```

# About

Alchemy provides you with Swifty APIs for everything you need to build production-ready backends.

- Simple, fast **routing engine**.
- Powerful **dependency injection** container.
- Expressive, Swifty database ORM supporting MySQL and Postgres.
- Database agnostic query builder and schema **migrations**.
- Robust job queues backed by Redis or SQL.
- Supporting libraries to import your typesafe backend APIs directly into Swift frontends.
- First class support for [Plot](https://github.com/JohnSundell/Plot), a typesafe HTML DSL.

## Why Alchemy?

Swift on the server is exciting but also relatively nascant ecosystem. Building a backend with it can be daunting and the pains of building in a new ecosystem can get in the way. involve wading through many tools, spread across lots of repos with partial features or incomplete documentation. 

The goal of Alchemy is to provide a robust, batteries included framework with everything you need to build production ready backends. Stay focused on building your next amazing project in elegant, Swifty style without sweating the details.

## Guiding principles

- *Batteries included*: With Routing, an ORM, advanced Redis & SQL support, Authentication, Cron, Caching and much more, `import Alchemy` gives you all the pieces you need to start building a production grade server app.
- *Convention over configuration*: APIs focus on simple syntax with lots of baked in convention so you can build much more with less code. This doesn't mean you can't customize; there's always an escape hatch to configure things your own way.
- *Ease of use*: A fully documented codebase organized in a single repo make it easy to get building, extending and contributing.
- *Keep it Swifty*: Swift is built to write concice, safe and elegant code. Alchemy leverages it's best parts to help you write great code faster and obviate entire classes of backend bugs.

# Get Started

## Install Alchemy

The Alchemy CLI can help you get started. It is installable with [Mint](https://github.com/yonaskolb/Mint).

```shell
mint install alchemy-swift/cli@main
```

## Create a New App

1. `alchemy new MyNewProject`
2. `cd MyNewProject`
3. `swift run`
4. view your brand new app at http://localhost:8080

You'll be guided through picking a new project template, either `Backend` or `Fullstack`.

Check out the [deployment guide](Docs/9_Deploying.md) for deploying to Linux or Docker.

## Swift Package Manager

You can also add Alchemy to your project manually with the [Swift Package Manager](https://github.com/apple/swift-package-manager). Until `1.0.0` is released, minor version changes might be breaking, so you may want to use `upToNextMinor`.

```swift
.package(url: "https://github.com/alchemy-swift/alchemy", .upToNextMinor(from: "0.2.0"))
```

# Usage

The [Docs](Docs#docs) provide a step by step walkthrough of everything Alchemy has to offer. They also touch on essential core backend concepts for developers new to server side development. Below are some of the core pieces.

## Getting started with routing

Each Alchemy project starts with an implemention of the `Application` protocol. It has a single `boot()` for you to set up your app. In `boot()` you'll define your configurations, routes, jobs, and anything else needed to set up your application.

Routing is done with action functions `get()`, `post()`, `delete()`, etc on the application.

```swift
@main
struct App: Application {
    func boot() {
        get("/hello") { req in
            return "Hello, World!"
        }

        post("/say_hello") { req -> String in
            let name = req.query(for: "name")!
            return "Hello, \(name)"
        }
    }
}
```

Route handlers will automatically convert returned Swift.Codable types to JSON.

```swift
struct Todo {
    let name: String
    let isComplete: Bool
    let created: Date
}

post("/json") { req -> Todo in
    return Todo(name: "Laundry", isComplete: false, created: Date())
}
```

You can also bundle groups of routes together with controllers.

```swift
struct TodoController: Controller {
    func route(_ app: Application) {
        app
            .get("/todo", getAllTodos)
            .post("/todo", createTodo)
            .patch("/todo/:id", updateTodo)
    }
    
    func getAllTodos(req: Request) -> [Todo] {
        ...
    }
    
    func createTodo(req: Request) -> Todo {
        ...
    }
    
    func updateTodo(req: Request) -> Todo {
        ...
    }
}

// Register the controller
myApp.controller(TodoController())
```

## Environment variables

## Services & dependency injection

## SQL queries

## Rune ORM

## Middleware

## Authentication

## Redis & caching

## Queues

## Scheduling tasks

# Contributing

Alchemy was designed to make it easy for you to contribute code. It's a single codebase with special attention given to readable code and documentation, so don't be afraid to dive in and submit PRs for bug fixes, documentation cleanup, forks or tune ups!

You can report bugs, contribute features, or just say hi on [Github discussions](https://github.com/alchemy-swift/alchemy/discussions) and [Discord](https://discord.gg/74Bq29q22u).