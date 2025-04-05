import NIO

// MARK: Aliases

/// The application lifecyle
public var Life: Lifecycle { Container.$lifecycle }

/// The application Environment
public var Env: Environment { Container.$env }

/// The `EventLoop` your code is currently running on, or the next one from your
/// app's `EventLoopGroup` if your code isn't running on an `EventLoop`.
public var Loop: EventLoop { Container.$eventLoop }

/// The main `EventLoopGroup` of your Application.
public var LoopGroup: EventLoopGroup { Container.$eventLoopGroup }

/// A thread pool to run expensive work on.
public var Thread: NIOThreadPool { Container.$threadPool }

/// The current application.
public internal(set) var Main: Application {
    get { Container.main.application }
    set { Container.main.application = newValue }
}

// MARK: Services

extension Container {
    var application: Application {
        get {
            guard let $_application else {
                preconditionFailure("The main application hasn't been registered. Has `app.willRun` been called?")
            }

            return $_application
        }
        set { $_application = newValue }
    }

    @Singleton var _application: Application? = nil
    @Singleton public var lifecycle = Lifecycle(app: application)
    @Singleton public var env: Environment = .createDefault()
    @Singleton public var threadPool: NIOThreadPool = .singleton
    @Singleton public var eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: isTest ? 1 : System.coreCount)

    @Factory public var eventLoop: EventLoop {
        guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !isTest else {
            // With async/await there is no guarantee that you'll
            // be running on an event loop. When one is needed,
            // return a random one for now.
            return $eventLoopGroup.next()
        }

        return current
    }
}
