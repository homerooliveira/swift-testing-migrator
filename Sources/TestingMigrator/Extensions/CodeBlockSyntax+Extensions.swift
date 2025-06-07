import SwiftSyntax

extension CodeBlockSyntax {
    func removingCalls(to methods: Set<String>) -> CodeBlockSyntax? {
        let rewriter = SuperMethodsRemover(methods: methods)
        return rewriter.rewrite(self).as(CodeBlockSyntax.self) ?? self
    }
}
