import SwiftParser
public import SwiftSyntax

public final class Rewriter {
    let rewriters = [
        ImportRewriter(),
        ClassRewriter(),
        // Handle all XCTAssert comparison functions
        XCTAssertRewriter(),
        // Handle all XCTAssert boolean and nil assertions
        XCTAssertBoolRewriter(),
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
