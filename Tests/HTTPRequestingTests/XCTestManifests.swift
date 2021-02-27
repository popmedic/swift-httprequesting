import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(HTTPRequestTests.allTests)
    ]
}
#endif
