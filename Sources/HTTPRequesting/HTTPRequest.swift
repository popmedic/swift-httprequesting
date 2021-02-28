import Foundation
import Network

/**
 NWHTTPRequest uses NWConnection as the Connection Connecting with
 http request
 */
public typealias NWHTTPRequest = HTTPRequest<NWConnection>

/**
 HTTPRequest - a **very** simple http request client for bypassing ATS.
 Typically use NWConnection as the Connection type
 */
public struct HTTPRequest<Connection: Connecting> {
    /**
     Initializes a new request
     - parameters:
     - url: location to request
     - method: http method, **only supports get method**
     - headers: http headers, will be merged with defaults
     - timeout: time interval (seconds) till canceling the request
     - interface: required interface to send the request on
     - returns: a new `HTTPRequest` for calling
     - note: currently only supports get method
     */
    public init(url: URL,
                method: Method = .get,
                headers: [String: String]? = nil,
                timeout: TimeInterval = 20,
                required interface: NWInterface.InterfaceType? = nil) {
        precondition(method == .get, "Only GET method supported")
        self.url = url
        self.method = method
        self.headers = normalize(headers: headers)
        self.timeout = timeout
        self.interface = interface
    }

    /**
     Call the request
     - parameters:
     - queue: dispatch queue to send the request on
     - handle: http request handler that will be called on every connection state
     - complete: http request completion that will be called when the request is complete
     - throws: HTTPRequestError
     */
    public func call(insecured: Bool = false,
                     queue: DispatchQueue? = nil,
                     handle: Handler? = nil,
                     complete: Completion? = nil) throws {
        let (validatedHost, scheme) = try validate(url: url)
        let host = NWEndpoint.Host(validatedHost)

        let sanitizedPort = sanitize(port: url.port, with: scheme)
        let port = NWEndpoint.Port(integerLiteral: sanitizedPort)

        let tcp = NWProtocolTCP.Options()
        tcp.connectionTimeout = try validate(timeout: timeout)

        let tls = NWProtocolTLS.Options()
        if insecured {
            sec_protocol_options_set_verify_block(
                tls.securityProtocolOptions,
                { _, _, complete in complete(true) },
                queue ?? .httpRequest
            )
        }

        let params = isSecure(scheme: scheme) ? NWParameters(tls: tls, tcp: tcp) : .tcp
        if let interface = interface { params.requiredInterfaceType = interface }

        var connection = Connection(host: host, port: port, using: params)
        let timer = deadline(connection: connection, complete: complete)

        receive(connection: connection,
                timer: timer,
                handle: handle)

        connection.stateUpdateHandler = { (state) in
            self.updated(connection: connection,
                         state: state,
                         timer: timer,
                         handle: handle,
                         complete: complete)
        }
        connection.start(queue: queue ?? .httpRequest)
    }

    private let url: URL
    private let method: Method
    private let headers: [String: String]
    private let timeout: TimeInterval
    private let interface: NWInterface.InterfaceType?
}

public extension HTTPRequest {
    typealias Handler = (HTTPRequestError?, Data?) -> Void
    typealias Completion = () -> Void

    enum Method {
        case connect, delete, get, head, options, patch, post, put, trace
        var string: String { "\(self)".uppercased() }
    }
}

private extension HTTPRequest {
    func send(connection: Connection,
              timer: DispatchSourceTimer,
              handle: Handler?) {
        let path = url.path.isEmpty ? "/" : url.path
        let query = url.query?.isEmpty ?? true ? "" : "?\(url.query!)"
        let content =
            "\(method.string) \(path)\(query) HTTP/1.1\r\n" +
            "Host: \((try? validate(url: url))?.host ?? "0.0.0.0")\r\n" +
            headers.map { "\($0.key): \($0.value)\r\n" }.joined() +
            "\r\n"
        connection.send(
            content: content.data(using: .ascii),
            contentContext: .defaultMessage,
            isComplete: true,
            completion: NWConnection.SendCompletion.contentProcessed({ (error) in
                if let error = error {
                    handle?(.send(error), nil) ?? ()
                    connection.cancel()
                }
            }
            )
        )
    }

    func receive(connection: Connection,
                 timer: DispatchSourceTimer,
                 handle: Handler?) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: Int(UInt16.max),
            completion: { (data, _, isComplete, error) in
                if let data = data {
                    handle?(nil, data)
                }
                if isComplete {
                    connection.cancel()
                } else if let error = error {
                    handle?(.receive(error), nil)
                } else {
                    self.receive(connection: connection,
                                 timer: timer,
                                 handle: handle)
                }
            }
        )
    }

    func updated(connection: Connection,
                 state: NWConnection.State,
                 timer: DispatchSourceTimer,
                 handle: Handler?,
                 complete: Completion?) {
        switch state {
        case .cancelled:
            timer.cancel()
            complete?()
        case .failed(let error):
            handle?(HTTPRequestError.connection(error), nil)
            connection.cancel()
        case .preparing:
            break
        case .ready:
            send(connection: connection, timer: timer, handle: handle)
        case .setup:
            break
        case .waiting(let error):
            handle?(HTTPRequestError.wait(error), nil)
            connection.cancel()
        default:
            break
        }
    }

    func deadline(connection: Connection,
                  complete: Completion?) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: .deadlineTimer)
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler {
            connection.cancel()
        }
        timer.resume()
        return timer
    }
}

private func normalize(headers: [String: String]?) -> [String: String] {
    var normalized = requiredHeaders
    if let headers = headers {
        normalized = normalized.merging(headers) { _, value in value }
    }
    return normalized
}
private func validate(url: URL) throws -> (host: String, scheme: String) {
    guard let scheme = url.scheme,
          isHTTP(scheme: scheme),
          let host = url.host else {
        throw HTTPRequestError.badURL(url)
    }
    return (host, scheme)
}
private func sanitize(port: Int?, with scheme: String) -> UInt16 {
    let sanitized: UInt16
    if let port = port, port < UInt16.max, port > UInt16.min {
        sanitized = UInt16(port)
    } else {
        sanitized = isSecure(scheme: scheme) ? httpsPort : httpPort
    }
    return sanitized
}
private func validate(timeout: TimeInterval) throws -> Int {
    guard timeout >= 0 else { throw HTTPRequestError.negitiveTimeout}
    if timeout >= Double(Int.max) { throw HTTPRequestError.timeoutOutOfBounds }
    return Int(timeout)
}
private func isHTTP(scheme: String) -> Bool {
    isInsecure(scheme: scheme) || isSecure(scheme: scheme)
}
private func isInsecure(scheme: String) -> Bool { scheme.lowercased() == "http" }
private func isSecure(scheme: String) -> Bool { scheme.lowercased() == "https" }

private let httpsPort: UInt16 = 443
private let httpPort: UInt16 = 80
private let requiredHeaders = [
    "User-Agent": "generic/1.0",
    "Accept": "*/*",
    "Connection": "close"
]

private extension DispatchQueue {
    static var httpRequest = DispatchQueue(
        label: "com.kscardina.httpRequest.serial.queue",
        qos: .background,
        attributes: []
    )
    static var deadlineTimer = DispatchQueue(
        label: "com.kscardina.deadlineTimer.queue",
        qos: .background,
        attributes: []
    )
}
