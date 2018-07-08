import NIO
import NIOHTTP1
import NetService
import Socket
import class Foundation.RunLoop

class MyServiceDelegate: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("Will publish: \(sender)")
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        print("Did publish: \(sender)")
    }
    
    func netService(_ sender: NetService, didNotPublish error: Error) {
        print("Did not publish: \(sender), because: \(error)")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("Did stop: \(sender)")
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith socket: Socket) {
        print("Did accept connection: \(sender), from: \(socket.remoteHostname)")
        print(try! socket.readString() ?? "")
        try! socket.write(from: "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, world!")
        socket.close()
    }
}

public class KarbonService {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    let threadPool = BlockingIOThreadPool(numberOfThreads: 6)
    
    let host: String
    let port: Int
    
    var netService: NetService?
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    public func start() throws {
        threadPool.start()

        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then {_ in
                    channel.pipeline.add(handler: RequestHandler())
                }
            }
            
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        let channel = try { () -> Channel in
            return try bootstrap.bind(host: host, port: port).wait()
        }()
        
        guard let localAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
        
        
        netService = NetService(domain: "local.", type: "_http._tcp.", name: "karbon", port: Int32(localAddress.port!))
        let serviceDelegate = MyServiceDelegate()
        netService?.delegate = serviceDelegate
        netService?.publish()
        RunLoop.main.run()
        print("Advertised service and Runloop started.")
        try channel.closeFuture.wait()
    }
    
    public func stop() {
        netService?.stop()
        try! threadPool.syncShutdownGracefully()
        try! group.syncShutdownGracefully()
        print("Server closed")
    }
}



