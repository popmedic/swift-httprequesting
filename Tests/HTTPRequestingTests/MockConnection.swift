//
//  File.swift
//  
//
//  Created by Kevin Scardina on 2/21/21.
//

import Foundation
import Network
@testable import HTTPRequesting

class MockConnection: Connecting {
	static var stateUpdateHandler: ((NWConnection.State) -> Void)?
	var stateUpdateHandler: ((NWConnection.State) -> Void)? {
		get { MockConnection.stateUpdateHandler }
		set { MockConnection.stateUpdateHandler = newValue }
	}
	static var initHost: NWEndpoint.Host?
	static var initPort: NWEndpoint.Port?
	static var initUsing: NWParameters?
	static var startCallCount = 0
	static var startQueue: DispatchQueue?
	static var sendCallCount = 0
	static var sendContent: Data?
	static var sendContentContext: NWConnection.ContentContext?
	static var sendIsComplete: Bool?
	static var sendCompletion: NWConnection.SendCompletion?
	static var receiveCallCount = 0
	static var receiveMinimumIncompleteLength: Int?
	static var receiveMaximumLength: Int?
	static var receiveCompletion: ((Data?, NWConnection.ContentContext?, Bool, NWError?) -> Void)?
	static var cancelCallCount = 0
	
	static func reset() {
		initHost = nil
		initPort = nil
		initUsing = nil
		stateUpdateHandler = nil
		startCallCount = 0
		startQueue = nil
		sendCallCount = 0
		sendContent = nil
		sendContentContext = nil
		sendIsComplete = nil
		sendCompletion = nil
		receiveCallCount = 0
		receiveMinimumIncompleteLength = nil
		receiveMaximumLength = nil
		receiveCompletion = nil
		cancelCallCount = 0
	}
	
	required init(host: NWEndpoint.Host,
				  port: NWEndpoint.Port,
				  using: NWParameters) {
		MockConnection.initHost = host
		MockConnection.initPort = port
		MockConnection.initUsing = using
	}
	
	func start(queue: DispatchQueue) {
		MockConnection.startQueue = queue
		MockConnection.startCallCount += 1
	}
	
	func send(content: Data?,
			  contentContext: NWConnection.ContentContext,
			  isComplete: Bool,
			  completion: NWConnection.SendCompletion) {
		MockConnection.sendContent = content
		MockConnection.sendContentContext = contentContext
		MockConnection.sendIsComplete = isComplete
		MockConnection.sendCompletion = completion
		MockConnection.sendCallCount += 1
	}
	
	func receive(minimumIncompleteLength: Int,
				 maximumLength: Int,
				 completion: @escaping (Data?,
										NWConnection.ContentContext?,
										Bool,
										NWError?) -> Void) {
		MockConnection.receiveMinimumIncompleteLength = minimumIncompleteLength
		MockConnection.receiveMaximumLength = maximumLength
		MockConnection.receiveCompletion = completion
		MockConnection.receiveCallCount += 1
	}
	
	func cancel() {
		MockConnection.cancelCallCount += 1
	}
}
