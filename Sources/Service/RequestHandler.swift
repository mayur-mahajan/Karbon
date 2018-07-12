import NIOHTTP1
import NIO

public final class RequestHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse
        
        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }
        
        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }
        
        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }
    
    private var buffer: ByteBuffer! = nil
    private var keepAlive = false
    private var state = State.idle
    
    private var infoSavedRequestHead: HTTPRequestHead?
    private var infoSavedBodyBytes: Int = 0
    
    private var continuousCount: Int = 0
    
    private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    private var handlerFuture: EventLoopFuture<Void>?

    public init() {
    }

    func handleInfo(ctx: ChannelHandlerContext, request: HTTPServerRequestPart) {
        switch request {
        case .head(let request):
            self.infoSavedRequestHead = request
            self.infoSavedBodyBytes = 0
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
        case .body(buffer: let buf):
            self.infoSavedBodyBytes += buf.readableBytes
        case .end:
            self.state.requestComplete()
            let response = """
            HTTP method: \(self.infoSavedRequestHead!.method)\r
            URL: \(self.infoSavedRequestHead!.uri)\r
            body length: \(self.infoSavedBodyBytes)\r
            headers: \(self.infoSavedRequestHead!.headers)\r
            client: \(ctx.remoteAddress?.description ?? "zombie")\r
            IO: SwiftNIO Electric Boogaloo™️\r\n
            """
            self.buffer.clear()
            self.buffer.write(string: response)
            var headers = HTTPHeaders()
            headers.add(name: "Content-Length", value: "\(response.utf8.count)")
            ctx.write(self.wrapOutboundOut(.head(httpResponseHead(request: self.infoSavedRequestHead!, status: .ok, headers: headers))), promise: nil)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(self.buffer))), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }
    
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()
        
        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        self.handler = nil
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }
    
    private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
        var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
        let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }
        
        if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
            // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
            switch (request.isKeepAlive, request.version.major, request.version.minor) {
            case (true, 1, 0):
                // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
                head.headers.add(name: "Connection", value: "keep-alive")
            case (false, 1, let n) where n >= 1:
                // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
                head.headers.add(name: "Connection", value: "close")
            default:
                // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
                ()
            }
        }
        return head
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(ctx, reqPart)
            return
        }
        
        switch reqPart {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            
            var responseHead = httpResponseHead(request: request, status: HTTPResponseStatus.ok)
            responseHead.headers.add(name: "content-length", value: "13")
            let response = HTTPServerResponsePart.head(responseHead)
            ctx.write(self.wrapOutboundOut(response), promise: nil)
        case .body:
            break
        case .end:
            self.state.requestComplete()
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
            ctx.write(self.wrapOutboundOut(content), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }
    
    public func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    public func handlerAdded(ctx: ChannelHandlerContext) {
        self.buffer = ctx.channel.allocator.buffer(capacity: 13)
        self.buffer.write(staticString: "Hello Karbon!")
    }

}
