# Configuration

## Custom Run Arguments
When Alchemy is run, it takes arguments that modify how it runs. By default, it listens for requests on `::1` aka `localhost` at port `8888`. You can pass it `--port {some_port}` and `--host {some_host}` flags to alter that. You can also pass it a `--unixSocket {some_socket}` flag if you want it to listen on a unix socket.

There are other commands that can be passed such as `migrate`, but these are discussed in other parts of the guides.

If you're running it from Xcode, you can configure flags passed on launch by editing the current scheme and navigating to `Run` -> `Arguments`.

## Environment

Often you'll need to access environment variables of the running program. To do so, use the `Env` type.

```swift
// The type is inferred
let envBool: Bool = Env.current("some_bool")
let envInt: Int = Env.current.get("some_int")
let envString: String = Env.current.get("some_string")
```

### .env file

By default, environment variables are loaded from the process (`ProcessInfo.processInfo.environment`) as well as the file `.env` if it exists in the working directory of your project.

Inside your `.env` file, keys & values are separated with an `=`.

```bash
# A sample .env file (a file literally titled ".env" in the current directory)

APP_NAME=Alchemy
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack

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

### Custom env file name
If you'd like to load a custom env file name, you may pass your program an `APP_ENV` variable. If you do so, instead of loading the env file from `.env` it will attempt to load the environment from a file entitled `.{APP_ENV}`.

If you have separate environment variables for different server configurations (i.e. local dev, staging, production), you can pass your program a separate `APP_ENV` for each configuration so the right environment is loaded.

### Dynamic member lookup

If you're feeling fancy, `Env` supports dynamic member lookup.

```swift
let db: String? = Env.DB_DATABASE
let dbUsername: String? = Env.DB_USER
let dbPass: String? = Env.DB_PASS
```

## Xcode Caveats

You can use Xcode to run your project to take advantage of all the great tools built into it; debugging, breakpoints, memory graphs, testing, etc.

When working with Xcode there are a few finicky spots to be aware of.

### Setting a Custom Working Directory

By default, Xcode builds and runs your project in a **DerivedData** folder, separate from the root directory of your project. Unfortunately this means that files your running server may need to access, such as a `.env` file or a `public` directory, will not be available.

To solve this, edit your server target's scheme & change the working directory to the projects root folder. `Edit Scheme` -> `Run` -> `Options` -> `WorkingDirectory`.

### Debugger Issues

While the Xcode debugger is excellent for debugging and stepping through your Alchemy server, it can have issues. Sometimes, when trying to stop your program, the debugger crashes, leaving your program running in the background, still bound to the host & port it was running on.

You'll know this happens when you get an error after stopping your program
```
Message from debugger: The LLDB RPC server has exited unexpectedly. Please file a bug if you have reproducible steps.
Program ended with exit code: -1
```

When you try to re-run your program, you'll get the following error:
```
Error: bind(descriptor:ptr:bytes:): Address already in use (errno: 48)
Program ended with exit code: 1
```

While this seems to be an Xcode bug out of our control, the solution is simple. Find the PID of your running program based on the port it's running on.

```bash
$ lsof -i :8888

COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
MyServer  2362 josh   16u  IPv6 0xc9129434cded84ef      0t0  TCP localhost:ddi-tcp-1 (LISTEN)
Insomnia  7767 josh   33u  IPv6 0xc9129434d6687b6f      0t0  TCP localhost:58816->localhost:ddi-tcp-1 (CLOSE_WAIT)
```
Then kill the PID off the running program, in this case 2362.
```bash
kill 2362
```

You can also completely elimate this from happening by unchecking "Debug executable" under `Edit Scheme` -> `Run` -> `Info`.

_Up next: [Services & Fusion](2_Fusion.md)_

_[Table of Contents](/Docs)_