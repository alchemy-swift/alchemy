//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Fusion
import NIO
import NIOHTTP1
import NIOHTTP2
import ArgumentParser

public protocol Application {
    func setup()
    init()
}

enum StartupArgs {
    case serve(target: BindTo)
    case migrate(rollback: Bool = false)
}

enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

extension Application {
    func launch(_ args: StartupArgs) throws {
        // Setup environment
        _ = Env.current
        
        // Get the global `MultiThreadedEventLoopGroup`
        let group = try Container.global.resolve(MultiThreadedEventLoopGroup.self)
        
        // First, setup the application (on an `EventLoop` from the global group so `Loop.current` can be
        // used.)
        let setup = group.next()
            .submit(self.setup)
            
        switch args {
        case .migrate(let rollback):
            // Migrations need to be run on an `EventLoop`.
            try setup
                .flatMap { self.migrate(rollback: rollback, group: group) }
                .wait()
            print("Migrations finished!")
        case .serve(let target):
            try self.startServing(target: target, group: group)
        }
    }
    
    private func migrate(rollback: Bool, group: MultiThreadedEventLoopGroup)
        -> EventLoopFuture<Void>
    {
        return DB.default.migrate()
    }
    
    private func startServing(target: BindTo, group: MultiThreadedEventLoopGroup) throws {
        func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(HTTPHandler(responder: HTTPRouterResponder()))
            }
        }

        let socketBootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer(channel:))

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        defer {
            try! group.syncShutdownGracefully()
        }

        let channel = try { () -> Channel in
            switch target {
            case .ip(let host, let port):
                return try socketBootstrap.bind(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try socketBootstrap.bind(unixDomainSocketPath: path).wait()
            }
        }()

        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        
        let localAddress: String = "\(channelLocalAddress)"
        
        print("Server started and listening on \(localAddress).")

        // This will never unblock as we don't close the ServerChannel
        try channel.closeFuture.wait()
    }
}
