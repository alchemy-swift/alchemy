# Environment

Often you'll need to access environment variables of the running program. To do so, use the `Env` type.

```swift
// The type is inferred
let envBool: Bool = Env.current("some_bool")
let envInt: Int = Env.current.get("some_int")
let envString: String = Env.current.get("some_string")
```

## .env file

By default, environment variables are loaded from the process (`ProcessInfo.processInfo.environment`) as well as the file `.env` if it exists in the current directory.

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

## Custom env file name
If you'd like to load a custom env file name, you may pass your program an `APP_ENV` variable. If you do so, instead of loading the env file from `.env` it will attempt to load the environment from a file entitled `.{APP_ENV}`.

If you have separate environment variables for different server configurations (i.e. local dev, staging, production), you can pass your program a separate `APP_ENV` for each configuration so the right environment is loaded.

## Dynamic member lookup

If you're feeling fancy, `Env` supports dynamic member lookup.

```swift
let db: String? = Env.DB_DATABASE
let dbUsername: String? = Env.DB_USER
let dbPass: String? = Env.DB_PASS
```