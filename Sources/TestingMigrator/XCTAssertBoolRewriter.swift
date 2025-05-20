import SwiftSyntax

final class XCTAssertBoolRewriter: SyntaxRewriter {
    enum OperatorType {
        case equal
        case notEqual
        case exclamationMark
        
        var token: TokenSyntax {
            switch self {
            case .equal:
                .binaryOperator("==")
            case .notEqual:
                .binaryOperator("!=")
            case .exclamationMark:
                .exclamationMarkToken()
            }
        }
    }
    
    let functionName: String
    let functionNameReplacement: String
    let operatorType: OperatorType?
    
    init(
        functionName: String,
        functionNameReplacement: String,
        operatorType: OperatorType? = nil
    ) {
        self.functionName = functionName
        self.functionNameReplacement = functionNameReplacement
        self.operatorType = operatorType
    }
   
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check if this is an function call to the specified function
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              identifierExpr.baseName.text == functionName else {
            return ExprSyntax(node)
        }
        
        var arguments = node.arguments.filter { $0.label == nil }
        
        guard arguments.count >= 1 else {
            let newFunctionCall = node
                .with(\.arguments, arguments)
                .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(functionNameReplacement))))
            return ExprSyntax(newFunctionCall)
        }
        
        let firstArg = arguments[arguments.startIndex]
        
        if operatorType == .exclamationMark {
            let newExpression: any ExprSyntaxProtocol = if firstArg.expression.is(SequenceExprSyntax.self) {
                TupleExprSyntax(
                    elements: LabeledExprListSyntax(
                        [firstArg]
                    )
                )
            } else {
                firstArg.expression
            }
            
            let newArg = PrefixOperatorExprSyntax(
                operator: .exclamationMarkToken(),
                expression: newExpression
            )
            
            arguments[arguments.startIndex].expression = ExprSyntax(newArg)
        } else if let operatorType {
            let equalityExpr = BinaryOperatorExprSyntax(
                leadingTrivia: .space,
                operator: operatorType.token,
                trailingTrivia: .space
            )
            
            // Combine into a sequence expression
            let newExpr = SequenceExprSyntax(
                elements: ExprListSyntax([
                    firstArg.expression,
                    ExprSyntax(equalityExpr),
                    ExprSyntax(NilLiteralExprSyntax()),
                ])
            )
            
            arguments[arguments.startIndex].expression = ExprSyntax(newExpr)
        }

        arguments[arguments.index(before: arguments.endIndex)].trailingComma = nil
        
        let newFunctionCall = node
            .with(\.arguments, arguments)
            .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(functionNameReplacement))))

        return ExprSyntax(newFunctionCall)
    }
}
