import AsyncHTTPClient
import Fusion
import NIO

/// Provides easy access to some commonly used services in Alchemy. These services are Injected from
/// the global `Container`. You can add your own services in extensions if you'd like.
///
/// ```
/// Services.db
/// // equivalant to
/// Container.global.resolve(Database.self)
/// // equivalent to
/// @Inject
/// var db: Database
/// ```
public enum Services {}

extension Services {
    // MARK: Alchemy Services
    
    /// The main database of your app. This is **not** registered by default so don't forget to do
    /// so in your `Application.setup`!
    ///
    /// ```
    /// struct MyServer: Application {
    ///     func setup() {
    ///         Services.db = PostgresDatabase(
    ///             DatabaseConfig(
    ///                 socket: .ip(host: "localhost", port: 5432),
    ///                 database: "alchemy",
    ///                 username: "admin",
    ///                 password: "password"
    ///             )
    ///         )
    ///     }
    /// }
    /// // elsewhere
    /// Services.db
    ///     .runRawQuery("select * from users;")
    ///     .whenSuccess { rows in
    ///         print("Got \(rows.count) results!")
    ///     }
    /// ```
    public static var db: Database {
        get { Container.global.resolve(Database.self) }
        set { Container.global.register(singleton: Database.self) { _ in newValue } }
    }
    
    /// The router to which all incoming requests in your application are routed.
    public static var router: Router {
        Container.global.resolve(Router.self)
    }
    
    /// A scheduler for scheduling recurring tasks.
    public static var scheduler: Scheduler {
        Container.global.resolve(Scheduler.self)
    }
    
    /// An `HTTPClient` for making HTTP requests.
    ///
    /// - Note: see
    /// [async-http-client](https://github.com/swift-server/async-http-client)
    ///
    /// Usage:
    /// ```
    /// Services.client
    ///     .get(url: "https://swift.org")
    ///     .whenComplete { result in
    ///         switch result {
    ///         case .failure(let error):
    ///             ...
    ///         case .success(let response):
    ///             ...
    ///         }
    ///     }
    /// ```
    public static var client: HTTPClient {
        Container.global.resolve(HTTPClient.self)
    }
    
    // MARK: NIO Services
    
    /// The current `EventLoop`.
    public static var eventLoop: EventLoop {
        Container.global.resolve(EventLoop.self)
    }
    
    /// The `EventLoopGroup` of this application.
    public static var eventLoopGroup: EventLoopGroup {
        Container.global.resolve(EventLoopGroup.self)
    }
    
    /// A `NIOThreadPool` for running expensive/blocking work on.
    ///
    /// By default, this pool has a number of threads equal to the number of logical cores on this
    /// machine. This pool is created and started when first accessed.
    public static var threadPool: NIOThreadPool {
        Container.global.resolve(NIOThreadPool.self)
    }
    
    /// Register some commonly used services to `Container.global`.
    internal static func bootstrap() {
        // `Router`
        Container.global.register(singleton: Router.self) { _ in
            Router()
        }
        
        // `Scheduler`
        Container.global.register(singleton: Scheduler.self) { _ in
            Scheduler(scheduleLoop: Services.eventLoop)
        }
        
        // `EventLoop`
        Container.global.register(EventLoop.self) { _ in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
                fatalError("This code isn't running on an `EventLoop`!")
            }

            return current
        }
        
        // `HTTPClient`
        Container.global.register(singleton: HTTPClient.self) { container in
            let group = container.resolve(EventLoopGroup.self)
            return HTTPClient(eventLoopGroupProvider: .shared(group))
        }
        
        // `EventLoopGroup`
        Container.global.register(singleton: EventLoopGroup.self) { _ in
            MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
        
        // `NIOThreadPool`
        Container.global.register(singleton: NIOThreadPool.self) { _ in
            let pool = NIOThreadPool(numberOfThreads: System.coreCount)
            pool.start()
            return pool
        }
    }
    
    /// Register some commonly used services registered to `Container.global`.
    ///
    /// This should not be run on `EventLoop`!
    static func shutdown() throws {
        try Services.client.syncShutdown()
        // Shutdown the main database, if it exists.
        try Container.global.resolveOptional(Database.self)?.shutdown()
        try Services.threadPool.syncShutdownGracefully()
        try Services.eventLoopGroup.syncShutdownGracefully()
    }
}
