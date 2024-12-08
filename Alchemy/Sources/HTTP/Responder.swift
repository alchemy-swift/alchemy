import Foundation
import Hummingbird
import NIOCore

actor Responder: HTTPResponder {
    struct Context: RequestContext {
        public let localAddress: SocketAddress?
        public let remoteAddress: SocketAddress?
        public var coreContext: CoreRequestContextStorage

        public init(source: ApplicationRequestContextSource) {
            self.localAddress = source.channel.localAddress
            self.remoteAddress = source.channel.remoteAddress
            self.coreContext = .init(source: source)
        }
    }

    let logResponses: Bool
    let handler: RequestHandler

    init(handler: RequestHandler, logResponses: Bool) {
        self.handler = handler
        self.logResponses = logResponses
    }

    func respond(to hbRequest: Hummingbird.Request, context: Context) async throws -> Hummingbird.Response {
        let startedAt = Date()
        let req = hbRequest.request(context: context)
        let res = await handler.handle(request: req)
        logResponse(req: req, res: res, startedAt: startedAt)
        return res.hbResponse
    }

    fileprivate func logResponse(req: Request, res: Response, startedAt: Date) {
        guard logResponses else { return }

        let finishedAt = Date()
        let dateString = Formatters.date.string(from: finishedAt)
        let timeString = Formatters.time.string(from: finishedAt)
        let left = "\(dateString) \(timeString) \(req.method) \(req.path)"
        let right = "\(startedAt.elapsedString) \(res.status.code)"
        let dots = Log.dots(left: left, right: right)

        if Container.isXcode {
            let logString = "\(dateString.lightBlack) \(timeString) \(req.path) \(dots.lightBlack) \(finishedAt.elapsedString.lightBlack) \(res.status.code)"
            switch res.status.code {
            case 500...599:
                Log.critical(logString)
            case 400...499:
                Log.warning(logString)
            default:
                Log.comment(logString)
            }
        } else {
            var code = "\(res.status.code)"
            switch res.status.code {
            case 200...299:
                code = code.green
            case 400...499:
                code = code.yellow
            case 500...599:
                code = code.red
            default:
                code = code.white
            }

            Log.comment("\(dateString.lightBlack) \(timeString) \(req.method) \(req.path) \(dots.lightBlack) \(finishedAt.elapsedString.lightBlack) \(code)")
        }
    }
}

extension Hummingbird.Request {
    fileprivate func request(context: Responder.Context) -> Request {
        Request(
            method: method,
            uri: uri.string,
            headers: headers,
            body: .stream(sequence: body),
            localAddress: context.localAddress,
            remoteAddress: context.remoteAddress
        )
    }
}

extension Response {
    fileprivate var hbResponse: Hummingbird.Response {
        let responseBody: ResponseBody = switch body {
        case .buffer(let buffer):
            .init(byteBuffer: buffer)
        case .stream(let stream):
            .init(asyncSequence: stream)
        case .none:
            .init()
        }

        return .init(status: status, headers: headers, body: responseBody)
    }
}

private enum Formatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
