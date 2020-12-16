import Fusion
import NIO

/// Conforms `MultiThreadedEventLoopGroup` to `SingletonService` for easy use
/// via `Fusion` APIs around your app.
extension MultiThreadedEventLoopGroup: SingletonService {
    public static func singleton(
        in container: Container
    ) throws -> MultiThreadedEventLoopGroup {
        MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
}
