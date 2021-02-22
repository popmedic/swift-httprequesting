import Foundation
import Network

public protocol Connecting {
	var stateUpdateHandler: ((NWConnection.State) -> Void)? { get set }
	func start(queue: DispatchQueue)
	func send(content: Data?,
			  contentContext: NWConnection.ContentContext,
			  isComplete: Bool,
			  completion: NWConnection.SendCompletion)
	func receive(minimumIncompleteLength: Int,
				 maximumLength: Int,
				 completion: @escaping (Data?,
										NWConnection.ContentContext?,
										Bool,
										NWError?) -> Void)
	func cancel()
	init(host: NWEndpoint.Host, port: NWEndpoint.Port, using: NWParameters)
}

extension NWConnection: Connecting { /* noop */ }
