import SwiftSyntax

final class XCTAssertRewriter: SyntaxRewriter {
    let functionName: String
    let operatorName: String
    let functionNameReplacement: String
    
    init(functionName: String, operatorName: String, functionNameReplacement: String) {
        self.functionName = functionName
        self.operatorName = operatorName
        self.functionNameReplacement = functionNameReplacement
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check if this is an function call to the specified function
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.text == functionName else {
            return ExprSyntax(node)
        }
        
        var arguments = node.arguments.filter { $0.label == nil }
        
        // We need at least 2 arguments to create a comparison
        guard arguments.count >= 2 else {
            return ExprSyntax(node)
        }
        
        // Get the first two arguments
        let firstArg = arguments[arguments.startIndex].expression
        let secondIndex = arguments.index(after: arguments.startIndex)
        let secondArg = arguments[secondIndex].expression
        
        // Create a binary operator expression: firstArg == secondArg
        let equalityExpr = BinaryOperatorExprSyntax(
            leadingTrivia: .space,
            operator: .binaryOperator(operatorName),
            trailingTrivia: .space
        )
        
        // Combine into a sequence expression
        let newExpr = SequenceExprSyntax(
            elements: ExprListSyntax([
                firstArg,
                ExprSyntax(equalityExpr),
                secondArg
            ])
        )

        arguments[secondIndex].expression = ExprSyntax(newExpr)
        arguments[arguments.index(before: arguments.endIndex)].trailingComma = nil
        
        // Remove the first argument because the first and second arguments are now combined
        arguments.remove(at: arguments.startIndex)

        let newFunctionCall = node
            .with(\.arguments, arguments)
            .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(functionNameReplacement))))
            .with(\.leadingTrivia, node.leadingTrivia)

        return ExprSyntax(newFunctionCall)
    }
}
