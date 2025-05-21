import SwiftSyntax

final class ImportRewriter: SyntaxRewriter {
    weak var rewriter: Rewriter?
    
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token.tokenKind == .identifier("XCTest") else {
            return token
        }
        
        return .identifier("Testing")
    }
}
