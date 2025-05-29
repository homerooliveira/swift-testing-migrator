import SwiftSyntax

final class ImportRewriter: SyntaxRewriter {
    private(set) var importFound = false

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token.tokenKind == .identifier("XCTest") else {
            importFound = false
            return token
        }

        importFound = true
        return .identifier("Testing")
    }
}
