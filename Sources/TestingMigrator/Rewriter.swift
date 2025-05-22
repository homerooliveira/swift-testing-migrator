import SwiftParser
public import SwiftSyntax

public final class Rewriter {
    public struct Configuration {
        let useClass: Bool

        public init(useClass: Bool = true) {
            self.useClass = useClass
        }
    }
    let preRewriter = ImportRewriter()
    let rewriters: [SyntaxRewriter]

    public init(_ configuration: Configuration = .init()) {
        self.rewriters = [
            preRewriter,
            ClassRewriter(useClass: configuration.useClass),
            // Handle all XCTAssert comparison functions
            XCTAssertRewriter(),
            // Handle all XCTAssert boolean and nil assertions
            XCTAssertBoolRewriter(),
            XCTAssertThrowRewriter(),
        ]
    }
    
    public func rewrite(source: String) -> SourceFileSyntax {
        let sourceFile = Parser.parse(source: source)
        
        // let modifiedContent = preRewriter.visit(sourceFile)

        // guard preRewriter.importFound else {
        //     return nil
        // }

        return rewriters.reduce(sourceFile) { partialResult, next in
            next.visit(partialResult)
        }
    }
}
