import XCTest
import Network
@testable import HTTPRequesting

final class HTTPRequestTests: XCTestCase {
    override func setUp() {
        MockConnection.reset()
    }

    override func tearDown() {
        MockConnection.reset()
    }
}

extension HTTPRequestTests {
    func testCallBadURL() {
        func urlTester(string: String) {
            let url = URL(string: string)!
            let req = HTTPRequest<MockConnection>(url: url)
            XCTAssertThrowsError(try req.call()) { (error) in
                guard let error = error as? HTTPRequestError else {
                    XCTFail("should be a HTTPRequestError.badURL")
                    return
                }
                switch error {
                case .badURL(let newURL): XCTAssertEqual(url, newURL)
                default: XCTFail("should be badURL \(url)")
                }
            }
        }
        urlTester(string: "htpps://testing:80")
        urlTester(string: "httpss://testing")
        urlTester(string: "://testing;'/")
    }

    func testCallPortSetInURL() {
        let givenPort: UInt16 = 8080
        let url = URL(string: "http://test:\(givenPort)")!
        let req = HTTPRequest<MockConnection>(url: url, timeout: 10)
        XCTAssertNoThrow(try req.call())
        XCTAssertEqual(MockConnection.initPort?.rawValue, givenPort)
    }

    func testCallPortSetInSchemeSecure() {
        let expPort: UInt16 = 443
        let url = URL(string: "https://test")!
        let req = HTTPRequest<MockConnection>(url: url, timeout: 10)
        XCTAssertNoThrow(try req.call())
        XCTAssertEqual(MockConnection.initPort?.rawValue, expPort)
    }

    func testCallPortSetInSchemeInsecure() {
        let expPort: UInt16 = 80
        let url = URL(string: "http://test")!
        let req = HTTPRequest<MockConnection>(url: url, timeout: 10)
        XCTAssertNoThrow(try req.call())
        XCTAssertEqual(MockConnection.initPort?.rawValue, expPort)
    }

    func testCallNegativeTimeout() {
        let url = URL(string: "https://mytown")!
        let req = HTTPRequest<MockConnection>(url: url, timeout: -10)
        XCTAssertThrowsError(try req.call()) { (error) in
            guard let error = error as? HTTPRequestError else {
                XCTFail("should be a HTTPRequestError.negativeTimeout")
                return
            }
            switch error {
            case .negitiveTimeout: break
            default: XCTFail("should be negitiveTimeout")
            }
        }
    }

    func testCallTimeoutOutOfBounds() {
        let url = URL(string: "http://test")!
        let req = HTTPRequest<MockConnection>(url: url,
                                              timeout: Double(Int.max) + 1.0)
        XCTAssertThrowsError(try req.call()) { (error) in
            guard let error = error as? HTTPRequestError else {
                XCTFail("should be a HTTPRequestError.")
                return
            }
            switch error {
            case .timeoutOutOfBounds: break
            default: XCTFail("should be timeoutOutOfBounds")
            }
        }
    }

    func testCallRequireInterface() {
        func givenInterfaceTest(givenInterface: NWInterface.InterfaceType) {
            let url = URL(string: "http://test")!
            let req = HTTPRequest<MockConnection>(url: url,
                                                  timeout: 10,
                                                  required: givenInterface)
            XCTAssertNoThrow(try req.call())
            XCTAssertEqual(MockConnection.initUsing?.requiredInterfaceType,
                           givenInterface)
        }
        givenInterfaceTest(givenInterface: .cellular)
        givenInterfaceTest(givenInterface: .loopback)
        givenInterfaceTest(givenInterface: .other)
        givenInterfaceTest(givenInterface: .wifi)
        givenInterfaceTest(givenInterface: .wiredEthernet)
    }

    func testCallQueueSet() {
        let givenQueue = DispatchQueue(label: "test")
        let url = URL(string: "http://test")!
        let req = HTTPRequest<MockConnection>(url: url,
                                              timeout: 10)
        XCTAssertNoThrow(try req.call(queue: givenQueue))
        XCTAssertEqual(MockConnection.startQueue,
                       givenQueue)
    }

    func testCallStartGet() {
        let expMethod = HTTPRequest<MockConnection>.Method.get
        let expPath = "/"
        let expHost = "test"
        let expScheme = "http"
        let exp =
            "\(expMethod.string) \(expPath) HTTP/1.1\r\n" +
            "Host: \(expHost)\r\n" +
            "User-Agent: generic/1.0\r\n" +
            "Accept: */*\r\n" +
            "Connection: close\r\n" +
            "\r\n"
        let url = URL(string: "\(expScheme)://\(expHost)")!
        let req = HTTPRequest<MockConnection>(url: url,
                                              method: expMethod,
                                              timeout: 100)
        XCTAssertNoThrow(try req.call())
        guard let stateUpdateHandle = MockConnection.stateUpdateHandler else {
            XCTFail("state update handler should be set")
            return
        }
        stateUpdateHandle(NWConnection.State.ready)
        XCTAssertEqual(MockConnection.sendCallCount, 1)
        guard let data = MockConnection.sendContent else {
            XCTFail("should have gotten a send content")
            return
        }
        XCTAssertEqual(String(data: data, encoding: .ascii)?.count, exp.count)
    }

    func testCallStartGetQuery() {
        let expMethod = HTTPRequest<MockConnection>.Method.get
        let expPath = "/how/about"
        let expHost = "test"
        let expScheme = "http"
        let expQuery = "this=out&my=fish&friend+is+so+cool"
        let exp =
            "\(expMethod.string) \(expPath)?\(expQuery) HTTP/1.1\r\n" +
            "Host: \(expHost)\r\n" +
            "User-Agent: generic/1.0\r\n" +
            "Accept: html/text\r\n" +
            "Connection: close\r\n" +
            "Good: Bad\r\n" +
            "\r\n"
        let url = URL(string: "\(expScheme)://\(expHost)\(expPath)?\(expQuery)")!
        let req = HTTPRequest<MockConnection>(url: url,
                                              method: .get,
                                              headers: ["Good": "Bad",
                                                        "Accept": "html/text"],
                                              timeout: 10)
        XCTAssertNoThrow(try req.call())
        guard let stateUpdateHandle = MockConnection.stateUpdateHandler else {
            XCTFail("state update handler should be set")
            return
        }
        stateUpdateHandle(NWConnection.State.setup)
        stateUpdateHandle(NWConnection.State.preparing)
        stateUpdateHandle(NWConnection.State.ready)
        XCTAssertEqual(MockConnection.sendCallCount, 1)
        guard let data = MockConnection.sendContent else {
            XCTFail("should have gotten a send content")
            return
        }
        XCTAssertEqual(String(data: data, encoding: .ascii)?.count, exp.count)
    }

    func testCallStartCancelled() {
        let url = URL(string: "https://test/this/out?param=1&param2=something+else")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "complete called")
        XCTAssertNoThrow(try req.call(complete: { expectation.fulfill() }))
        guard let stateUpdateHandle = MockConnection.stateUpdateHandler else {
            XCTFail("state update handler should be set")
            return
        }
        stateUpdateHandle(NWConnection.State.cancelled)
        wait(for: [expectation], timeout: 0.5)
    }

    func testCallStartFailed() {
        let expError = NWError.posix(POSIXErrorCode.EACCES)
        let state = NWConnection.State.failed(expError)
        let url = URL(string: "https://test/this/out?param=1&param2=something+else")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "complete called")
        XCTAssertNoThrow(
            try req.call(
                handle: { error, _ in
                    expectation.fulfill()
                    guard let error = error else {
                        XCTFail("should have an error")
                        return
                    }
                    switch error {
                    case .connection(let err): XCTAssertEqual(expError, err)
                    default: XCTFail("should be connection \(expError)")
                    }
                }
            )
        )
        guard let stateUpdateHandle = MockConnection.stateUpdateHandler else {
            XCTFail("state update handler should be set")
            return
        }
        stateUpdateHandle(state)
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(MockConnection.cancelCallCount, 1)
    }

    func testCallStartWait() {
        let expError = NWError.posix(POSIXErrorCode.EACCES)
        let state = NWConnection.State.waiting(expError)
        let url = URL(string: "https://test/this/out?param=1")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "complete called")
        XCTAssertNoThrow(
            try req.call(
                handle: { error, _ in
                    expectation.fulfill()
                    guard let error = error else {
                        XCTFail("should have an error")
                        return
                    }
                    switch error {
                    case .wait(let err): XCTAssertEqual(expError, err)
                    default: XCTFail("should be connection \(expError)")
                    }
                }
            )
        )
        guard let stateUpdateHandle = MockConnection.stateUpdateHandler else {
            XCTFail("state update handler should be set")
            return
        }
        stateUpdateHandle(state)
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(MockConnection.cancelCallCount, 1)
    }

    func testCallRecieveError() {
        let expError = NWError.posix(POSIXErrorCode.EACCES)
        let url = URL(string: "https://test/this/out?param=1&param2=something+else")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "handle called")
        XCTAssertNoThrow(
            try req.call(
                handle: { error, data in
                    expectation.fulfill()
                    XCTAssertNil(data)
                    guard let error = error else {
                        XCTFail("should have an error")
                        return
                    }
                    switch error {
                    case .receive(let err): XCTAssertEqual(expError, err)
                    default: XCTFail("should be connection \(expError)")
                    }
                }
            )
        )
        guard let receiveCompletion = MockConnection.receiveCompletion else {
            XCTFail("state update handler should be set")
            return
        }
        receiveCompletion(nil, nil, false, expError)
        wait(for: [expectation], timeout: 0.5)
    }

    func testCallReceiveData() {
        let expData = "testing".data(using: .ascii)
        let url = URL(string: "https://test/this/out?param=1&param2=something+else")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "handle called")
        XCTAssertNoThrow(
            try req.call(
                handle: { error, data in
                    expectation.fulfill()
                    XCTAssertNil(error)
                    XCTAssertEqual(expData, data)
                }
            )
        )
        guard let receiveCompletion = MockConnection.receiveCompletion else {
            XCTFail("state update handler should be set")
            return
        }
        receiveCompletion(expData, nil, false, nil)
        wait(for: [expectation], timeout: 0.5)
    }

    func testCallUsePinsWithInsecure() {

    }

    func testCallReceiveDataComplete() {
        let expData = "testing".data(using: .ascii)
        let url = URL(string: "https://test/this/out?param=1&param2=something+else")!
        let req = HTTPRequest<MockConnection>(url: url)
        let expectation = XCTestExpectation(description: "handle called")
        XCTAssertNoThrow(
            try req.call(
                handle: { error, data in
                    expectation.fulfill()
                    XCTAssertNil(error)
                    XCTAssertEqual(expData, data)
                }
            )
        )
        guard let receiveCompletion = MockConnection.receiveCompletion else {
            XCTFail("state update handler should be set")
            return
        }
        receiveCompletion(expData, nil, true, nil)
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(MockConnection.cancelCallCount, 1)
    }
}

extension HTTPRequestTests {
    static var allTests = [
        ("testCallBadURL", testCallBadURL),
        ("testCallPortSetInURL", testCallPortSetInURL),
        ("testCallPortSetInSchemeSecure", testCallPortSetInSchemeSecure),
        ("testCallPortSetInSchemeInsecure", testCallPortSetInSchemeInsecure),
        ("testCallNegativeTimeout", testCallNegativeTimeout),
        ("testCallTimeoutOutOfBounds", testCallTimeoutOutOfBounds),
        ("testCallRequireInterface", testCallRequireInterface),
        ("testCallQueueSet", testCallQueueSet),
        ("testCallStartGet", testCallStartGet),
        ("testCallStartGetQuery", testCallStartGetQuery),
        ("testCallStartCancelled", testCallStartCancelled),
        ("testCallStartFailed", testCallStartFailed),
        ("testCallStartWait", testCallStartWait),
        ("testCallRecieveError", testCallRecieveError),
        ("testCallReceiveData", testCallReceiveData),
        ("testCallReceiveDataComplete", testCallReceiveDataComplete)
    ]
}
