# Commands

- [Writing a custom Command](#writing-a-custom-command)
  * [Adding Options, Flags, and help info](#adding-options-flags-and-help-info)
  * [Printing help info](#printing-help-info)
- [`make` Commands](#make-commands)

Often, you'll want to run specific tasks around maintenance, cleanup or productivity for your Alchemy app.

The `Command` interface makes this a cinche, allowing you to create custom commands to run your application with. It's built on the powerful [Swift Argument Parser](https://github.com/apple/swift-argument-parser) making it easy to add arguments, options, flags and help functionality to your custom commands. All commands have access to services registered in `Application.boot` so it's easy to interact with whatever database, queues, & other functionality that your app already has.

## Writing a custom Command 

To create a command, conform to the `Command` protocol, implement `func start()`, and register it with `app.registerCommand(...)`. Now, when you run your Alchemy app you may pass your custom command name as an argument to execute it.

For example, let's say you wanted a command that prints all user emails in your default database.

```swift
final class PrintUserEmails: Command {
    // see Swift Argument Parser for other configuration options
    static var configuration = CommandConfiguration(commandName: "print")

    func start() -> EventLoopFuture<Void> {
        User.all()
            .mapEach { user in
                print(user.email)
            }
            .voided()
    }
}
```

Now just register the command, likely in your `Application.boot`

```swift
app.registerCommand(PrintUserEmails.self)
```

and you can run your app with the `print` argument to run your command.

```
$ swift run MyApp print
...
jack@twitter.com
elon@tesla.com
mark@facebook.com
```

### Adding Options, Flags, and help info

Because `Command` inherits from Swift Argument Parser's `ParsableCommand` you can easily add flags, options, and configurations to your commands. There's also support for adding help & discussion strings that will show if your app is run with the `help` argument.

```swift
final class SyncUserData: Command {
    static var configuration = CommandConfiguration(commandName: "sync", discussion: "Sync all data for all users.")

    @Option var id: Int?
    @Flag(help: "Loaded data but don't save it.") var dry: Bool = false

    func start() -> EventLoopFuture<Void> {
        if let userId = id {
            // sync only a specific user's data
        } else {
            // sync all users' data
        }
    }
}
```

You can now pass options and flags to this command like so `swift run MyApp sync --id 2 --dry` and it run with the given arguments.

### Printing help info

Out of the box, your server can be run with the `help` argument to show all commands available to it, including any custom ones your may have registered.

```bash
$ swift run MyApp help
OVERVIEW: Run an Alchemy app.

USAGE: launch [--env <env>] <subcommand>

OPTIONS:
  -e, --env <env>         (default: env)
  -h, --help              Show help information.

SUBCOMMANDS:
  serve (default)
  migrate
  queue
  make:controller
  make:middleware
  make:migration
  make:model
  make:job
  make:view
  sync

  See 'launch help <subcommand>' for detailed help.
```

You can also pass a command name after help to get detailed information on that command, based on the information your provide in your `configuration`, options, flags, etc.

```bash
$ swift run MyApp help sync
OVERVIEW:
Sync all data for all users.

USAGE: MyApp sync [--id <id>] [--dry]

OPTIONS:
  -e, --env <env>         (default: env)
  --id <id>               Sync data for a specific user only.
  --dry                   Should data be loaded but not saved.
  -h, --help              Show help information.
```

Note that you can always pass `-e, --env <env-file>` to any command to have it load your environment from a custom env file before running.

## `make` Commands

Out of the box, Alchemy includes a variety of commands to boost your productivity and generate commonly used interfaces. These commands are prefaced with `make:`, and you can see all available ones with `swift run MyApp help`.

For example, the `make:model` command makes it easy to generate a model with the given fields. You can event generate a full populated Migration and Controller with CRUD routes by passing the `--migration` and `--controller` flags.

```bash
$ swift run Server make:model Todo id:increments:primary name:string is_done:bool user_id:bigint:references.users.id --migration --controller
🧪 create Sources/App/Models/Todo.swift
🧪 create Sources/App/Migrations/2021_09_24_11_07_02CreateTodos.swift
          └─ remember to add migration to your database config!
🧪 create Sources/App/Controllers/TodoController.swift
```

Like all commands, you may view the details & arguments of each make command with `swift run MyApp help <command>`.


_Next page: [Digging Deeper](10_DiggingDeeper.md)_

_[Table of Contents](/Docs#docs)_
