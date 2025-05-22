import SwiftParser
public import SwiftSyntax

public final class Rewriter {
    public struct Configuration {
        let useClass: Bool

        public init(useClass: Bool = true) {
            self.useClass = useClass
        }
    }

    let rewriters: [SyntaxRewriter]

    public init(_ configuration: Configuration = .init()) {
        self.rewriters = [
            ImportRewriter(),
            ClassRewriter(useClass: configuration.useClass),
            // Handle all XCTAssert comparison functions
            XCTAssertRewriter(),
            // Handle all XCTAssert boolean and nil assertions
            XCTAssertBoolRewriter(),
        ]
    }
    
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
