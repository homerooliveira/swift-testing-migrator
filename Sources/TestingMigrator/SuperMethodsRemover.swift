import SwiftSyntax

final class SuperMethodsRemover: SyntaxRewriter {
    private let methods: Set<String>

    init(methods: Set<String>) {
        self.methods = methods
    }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        let filteredStatements = node.statements.filter { item in
            !isSuperSetupCallItem(item)
        }

        return node.with(\.statements, filteredStatements)
    }

    private func isSuperSetupCallItem(_ item: CodeBlockItemSyntax) -> Bool {
        // Check if the item is directly a FunctionCallExprSyntax (super.setUp())
        if let functionCall = item.item.as(FunctionCallExprSyntax.self) {
            return isSuperSetupCall(functionCall)
        }

        // Check if the item is an ExpressionStmtSyntax containing a super setup call
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
            if let functionCall = exprStmt.expression.as(FunctionCallExprSyntax.self) {
                return isSuperSetupCall(functionCall)
            }

            // Handle try expressions: try super.setUpWithError()
            if let tryExpr = exprStmt.expression.as(TryExprSyntax.self),
                let functionCall = tryExpr.expression.as(FunctionCallExprSyntax.self)
            {
                return isSuperSetupCall(functionCall)
            }
        }

        return false
    }

    private func isSuperSetupCall(_ functionCall: FunctionCallExprSyntax) -> Bool {
        guard let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
            memberAccess.base?.is(SuperExprSyntax.self) == true,
            methods.contains(memberAccess.declName.baseName.text)
        else {
            return false
        }
        return true
    }
}
