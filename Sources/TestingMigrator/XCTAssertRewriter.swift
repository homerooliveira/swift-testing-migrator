import SwiftSyntax

final class XCTAssertRewriter: SyntaxRewriter {
    private let assertions: [String: (operator: String, replacement: String)] = [
        "XCTAssertEqual": ("==", "#expect"),
        "XCTAssertNotEqual": ("!=", "#expect"),
        "XCTAssertIdentical": ("===", "#expect"),
        "XCTAssertNotIdentical": ("!==", "#expect"),
        "XCTAssertGreaterThan": (">", "#expect"),
        "XCTAssertGreaterThanOrEqual": (">=", "#expect"),
        "XCTAssertLessThanOrEqual": ("<=", "#expect"),
        "XCTAssertLessThan": ("<", "#expect")
    ]
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check if this is a function call to any of our supported assertions
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              let assertInfo = assertions[identifierExpr.baseName.text] else {
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
            operator: .binaryOperator(assertInfo.operator),
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
            .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(assertInfo.replacement))))
            .with(\.leadingTrivia, node.leadingTrivia)
        
        return ExprSyntax(newFunctionCall)
    }
}
