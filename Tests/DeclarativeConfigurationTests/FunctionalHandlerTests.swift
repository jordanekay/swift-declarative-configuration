import XCTest
@testable import FunctionalHandler

final class FunctionalHandlerTests: XCTestCase {
    func testHandler() {
        class Object {
            @FunctionalHandler<(Int, Int), Int>
            var sum = .init { $0 + $1 } // You can specify default handler
            
            @FunctionalHandler<Int, Void>
            var handleSumResult // or leave it nil
            
            func sum(_ a: Int, _ b: Int) -> Int? {
                let result = $sum?((a, b)) 
                if let result = result {
                    $handleSumResult?(result)
                }
                return result
            }
        }
        
        let object = Object()
        let expectation = XCTestExpectation()
        let a = 10
        let b = 20
        let c = 30
        
        object.handleSumResult { int in
            XCTAssertEqual(int, c)
        }
        
        XCTAssertEqual(object.sum(a, b), c)
        
        object.handleSumResult(action: nil)
        
        XCTAssertEqual(object.sum(a, b), c)
        
        XCTAssertTrue(expectation.expectedFulfillmentCount == 1)
    }
}
