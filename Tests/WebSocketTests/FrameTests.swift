import XCTest
@testable import WebSocket

class FrameTests: XCTestCase {
<<<<<<< HEAD
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
    func testMaskPong() {
        let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
        let frame = Frame(opCode: .Pong, data: [], maskKey: maskKey)
        let data = frame.getData()
=======
    func testMaskPong() {
        let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
        let frame = Frame(opCode: .pong, data: [], maskKey: maskKey)
        let data = frame.data
>>>>>>> upstream/master
        var pass = Data()
        pass.append(0b10001010)
        pass.append(0b10000000)
        pass += maskKey
        pass += []
<<<<<<< HEAD
        XCTAssert(data==pass, "Frame does not match with Pong case")
    }
    func testMaskText() {
      let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
      let frame = Frame(opCode: .Text, data: "Hello".data, maskKey: maskKey)
      let data = frame.getData()
      let pass = Data([0x81, 0x85, 0x39, 0xfa, 0xab, 0x35, 0x71, 0x9f, 0xc7, 0x59, 0x56])
      XCTAssert(data==pass, "Frame does not match with Text case")
=======
        XCTAssert(data == pass, "Frame does not match with pong case")
    }

    func testMaskText() {
      let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
      let frame = Frame(opCode: .text, data: "Hello", maskKey: maskKey)
      let data = frame.data
      let pass = Data([0x81, 0x85, 0x39, 0xfa, 0xab, 0x35, 0x71, 0x9f, 0xc7, 0x59, 0x56])
      XCTAssert(data == pass, "Frame does not match with text case")
>>>>>>> upstream/master
    }
}

extension FrameTests {
<<<<<<< HEAD
    static var allTests: [(String, FrameTests -> () throws -> Void)] {
        return [
        ("testMaskPong", testMaskPong),
        ("testMaskText", testMaskText),
=======
    static var allTests: [(String, (FrameTests) -> () throws -> Void)] {
        return [
            ("testMaskPong", testMaskPong),
            ("testMaskText", testMaskText),
>>>>>>> upstream/master
        ]
    }
}
