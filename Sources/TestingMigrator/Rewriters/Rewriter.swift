import SwiftParser
import SwiftSyntax

struct Rewriter {
    let rewriters: [SyntaxRewriter]

    init(useClass: Bool) {
        self.rewriters = [
            ImportRewriter(),
            XCTAssertThrowRewriter(),
            XCTAssertUnifiedRewriter(),
            ClassRewriter(useClass: useClass),
        ]
    }

    func rewrite(source: String) -> String {
        let sourceFile = Parser.parse(source: source)

        let result = rewriters.reduce(sourceFile) { partialResult, next in
            next.visit(partialResult)
        }

        return result.description
    }
}
