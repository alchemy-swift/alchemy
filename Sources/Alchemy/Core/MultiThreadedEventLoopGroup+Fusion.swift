import NIO

extension MultiThreadedEventLoopGroup: SingletonService {
    public static func singleton(in container: Container) throws -> MultiThreadedEventLoopGroup {
        MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
}
