import Testing
@testable import MathBridge

@Suite("MathBridge Tests")
struct MathBridgeTests {

    @Test func addPositive() {
        #expect(MathBridge.add(2, 3) == 5)
    }

    @Test func addNegative() {
        #expect(MathBridge.add(-1, 1) == 0)
        #expect(MathBridge.add(-2, -3) == -5)
    }

    @Test func subtract() {
        #expect(MathBridge.subtract(3, 2) == 1)
        #expect(MathBridge.subtract(2, 3) == -1)
        #expect(MathBridge.subtract(5, 5) == 0)
    }

    @Test func multiply() {
        #expect(MathBridge.multiply(2, 3) == 6)
        #expect(MathBridge.multiply(0, 100) == 0)
        #expect(MathBridge.multiply(-2, -3) == 6)
    }

    @Test func divideNormal() throws {
        #expect(try MathBridge.divide(6, 2) == 3)
        #expect(try MathBridge.divide(10, 3) == 3)
    }

    @Test func divideByZero() {
        #expect(throws: MathBridge.MathError.divisionByZero) {
            try MathBridge.divide(6, 0)
        }
    }

    @Test func factorial() throws {
        #expect(try MathBridge.factorial(0) == 1)
        #expect(try MathBridge.factorial(1) == 1)
        #expect(try MathBridge.factorial(5) == 120)
        #expect(try MathBridge.factorial(10) == 3628800)
    }

    @Test func factorialNegative() {
        #expect(throws: MathBridge.MathError.negativeInput) {
            try MathBridge.factorial(-1)
        }
    }

    @Test func fibonacci() throws {
        #expect(try MathBridge.fibonacci(0) == 0)
        #expect(try MathBridge.fibonacci(1) == 1)
        #expect(try MathBridge.fibonacci(5) == 5)
        #expect(try MathBridge.fibonacci(10) == 55)
    }

    @Test func fibonacciNegative() {
        #expect(throws: MathBridge.MathError.negativeInput) {
            try MathBridge.fibonacci(-1)
        }
    }
}
