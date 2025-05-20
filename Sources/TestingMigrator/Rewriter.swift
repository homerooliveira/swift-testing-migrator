import SwiftParser
public import SwiftSyntax

public final class Rewriter {
    let rewriters = [
        ImportRewriter(),
        ClassRewriter(),
        TestCaseRewriter(),
        // XCTAssertEqual(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertEqual",
            operatorName: "==",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertNotEqual(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertNotEqual",
            operatorName: "!=",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertIdentical(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertIdentical",
            operatorName: "===",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertNotIdentical(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertNotIdentical",
            operatorName: "!==",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertGreaterThan(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertGreaterThan",
            operatorName: ">",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertGreaterThanOrEqual(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertGreaterThanOrEqual",
            operatorName: ">=",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertLessThanOrEqual(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertLessThanOrEqual",
            operatorName: "<=",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertLessThan(x, y)
        XCTAssertRewriter(
            functionName: "XCTAssertLessThan",
            operatorName: "<",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertTrue(x)
        XCTAssertBoolRewriter(
            functionName: "XCTAssertTrue",
            functionNameReplacement: "#expect"
        ),
        // XCTAssert(x)
        XCTAssertBoolRewriter(
            functionName: "XCTAssert",
            functionNameReplacement: "#expect"
        ),
        // XCTAssertFalse(x)
        XCTAssertBoolRewriter(
            functionName: "XCTAssertFalse",
            functionNameReplacement: "#expect",
            operatorType: .exclamationMark
        ),
        // XCTAssertNil(x)
        XCTAssertBoolRewriter(
            functionName: "XCTAssertNil",
            functionNameReplacement: "#expect",
            operatorType: .equal
        ),
        // XCTAssertNotNil(x)
        XCTAssertBoolRewriter(
            functionName: "XCTAssertNotNil",
            functionNameReplacement: "#expect",
            operatorType: .notEqual
        ),
        // XCTUnwrap(x)
        XCTAssertBoolRewriter(
            functionName: "XCTUnwrap",
            functionNameReplacement: "#require"
        ),
        // XCTFail(x)
        XCTAssertBoolRewriter(
            functionName: "XCTFail",
            functionNameReplacement: "Issue.record"
        ),
    ]
    
    public init() { }
    
    public func rewrite(source: String) -> SourceFileSyntax {
        let sourceFile = Parser.parse(source: source)
        
        return rewriters.reduce(sourceFile) { partialResult, next in
            next.visit(partialResult)
        }
    }
    
    func skipRewriting() {
        print("Skipping rewriting")
    }
}
