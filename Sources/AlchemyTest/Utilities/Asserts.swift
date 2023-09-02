import XCTest

public func AssertEqual<T: Equatable>(_ expression1: T, _ expression2: T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(expression1, expression2, message(), file: file, line: line)
}

public func AssertNotEqual<T: Equatable>(_ expression1: T, _ expression2: T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNotEqual(expression1, expression2, message(), file: file, line: line)
}

public func AssertNil(_ expression: Any?, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNil(expression, message(), file: file, line: line)
}

public func AssertFalse(_ expression: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalse(expression, message(), file: file, line: line)
}

public func AssertTrue(_ expression: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(expression, message(), file: file, line: line)
}

public func AssertThrowsError<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (_ error: Error) -> Void = { _ in }) async {
    do {
        _ = try await expression()
    } catch {
        XCTAssertThrowsError(try { throw error }(), message(), file: file, line: line, errorHandler)
    }
}

public func AssertNoThrow<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await expression()
    } catch {
        XCTAssertNoThrow(try { throw error }(), message(), file: file, line: line)
    }
}
