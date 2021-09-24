# Configuration

- [Run Commands](#run-commands)
  * [`serve`](#serve)
  * [`migrate`](#migrate)
  * [`queue`](#queue)
- [Environment](#environment)
  * [Dynamic Member Lookup](#dynamic-member-lookup)
  * [.env File](#env-file)
  * [Custom Environments](#custom-environments)
- [Working with Xcode](#working-with-xcode)
  * [Setting a Custom Working Directory](#setting-a-custom-working-directory)

## Run Commands

When Alchemy is run, it takes an argument that determines how it behaves on launch. When no argument is passed, the default command is `serve` which boots the app and serves it on the machine.

There are also `migrate` and `queue` commands which help run migrations and queue workers/schedulers respectively.

You can run these like so.

```shell
swift run Server migrate
```

Each command has options for customizing how it runs. If you're running your app from Xcode, you can configure launch arguments by editing the current scheme and navigating to `Run` -> `Arguments`.

If you're looking to extend your Alchemy app with your own custom commands, check out [Commands](13_Commands.md).

### Serve

> `swift run` or `swift run Server serve`

|Option|Default|Description|
|-|-|-|
|--host|127.0.0.1|The host to listen on|
|--port|3000|The port to listen on|
|--unixSocket|nil|The unix socket to listen on. Mutually exclusive with `host` & `port`|
|--workers|0|The number of workers to run|
|--schedule|false|Whether scheduled tasks should be scheduled|
|--migrate|false|Whether any outstanding migrations should be run before serving|
|--env|env|The environment to load|

### Migrate

> `swift run Server migrate`

|Option|Default|Description|
|-|-|-|
|--rollback|false|Should migrations be rolled back instead of applied|
|--env|env|The environment to load|

### Queue

> `swift run Server queue`

|Option|Default|Description|
|-|-|-|
|--name|`nil`|The queue to monitor. Leave empty to monitor `Queue.default`|
|--channels|`default`|The channels to monitor, separated by comma|
|--workers|1|The number of workers to run|
|--schedule|false|Whether scheduled tasks should be scheduled|
|--env|env|The environment to load|

## Environment

Often you'll need to access environment variables of the running program. To do so, use the `Env` type.

```swift
// The type is inferred
let envBool: Bool? = Env.current.get("SOME_BOOL")
let envInt: Int? = Env.current.get("SOME_INT")
let envString: String? = Env.current.get("SOME_STRING")
```

### Dynamic member lookup

If you're feeling fancy, `Env` supports dynamic member lookup.

```swift
let db: String? = Env.DB_DATABASE
let dbUsername: String? = Env.DB_USER
let dbPass: String? = Env.DB_PASS
```

### .env file

By default, environment variables are loaded from the process as well as the file `.env` if it exists in the working directory of your project.

Inside your `.env` file, keys & values are separated with an `=`.

```bash
# A sample .env file (a file literally titled ".env" in the working directory)

APP_NAME=Alchemy
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=alchemy
DB_USER=josh
DB_PASS=password

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
```

### Custom Environments

You can load your environment from another location by passing your app the `--env` option.

If you have separate environment variables for different server configurations (i.e. local dev, staging, production), you can pass your program a separate `--env` for each configuration so the right environment is loaded.

## Configuring Your Server

There are a couple of options available for configuring how your server is running. By default, the server runs over `HTTP/1.1`. 

### Enable TLS

You can enable running over TLS with `useHTTPS`.

```swift
func boot() throws {
    try useHTTPS(key: "/path/to/private-key.pem", cert: "/path/to/cert.pem")
}
```

### Enable HTTP/2

You may also configure your server with `HTTP/2` upgrades (will prefer `HTTP/2` but still accept `HTTP/1.1` over TLS). To do this use `useHTTP2`.

```swift
func boot() throws {
    try useHTTP2(key: "/path/to/private-key.pem", cert: "/path/to/cert.pem")
}
```

Note that the `HTTP/2` protocol is only supported over TLS, and so implies using it. Thus, there's no need to call both `useHTTPS` and `useHTTP2`; `useHTTP2` sets up both TLS and `HTTP/2` support.

## Working with Xcode

You can use Xcode to run your project to take advantage of all the great tools built into it; debugging, breakpoints, memory graphs, testing, etc.

When working with Xcode be sure to set a custom working directory.

### Setting a Custom Working Directory

By default, Xcode builds and runs your project in a **DerivedData** folder, separate from the root directory of your project. Unfortunately this means that files your running server may need to access, such as a `.env` file or a `Public` directory, will not be available.

To solve this, edit your server target's scheme & change the working directory to your package's root folder. `Edit Scheme` -> `Run` -> `Options` -> `WorkingDirectory`.

_Up next: [Services & Dependency Injection](2_Fusion.md)_

_[Table of Contents](/Docs#docs)_
