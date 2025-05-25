import SwiftParser
import SwiftSyntax

public struct Rewriter {
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
            XCTAssertThrowRewriter(),
            XCTAssertUnifiedRewriter(),
        ]
    }
    
    public func rewrite(source: String) -> String {
        let sourceFile = Parser.parse(source: source)

        let result = rewriters.reduce(sourceFile) { partialResult, next in
            next.visit(partialResult)
        }

        return result.description
    }
}
