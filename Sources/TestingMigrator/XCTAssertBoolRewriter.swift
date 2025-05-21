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
    
    private let assertions: [String: (replacement: String, operatorType: OperatorType?)] = [
        "XCTAssertTrue": ("#expect", nil),
        "XCTAssert": ("#expect", nil),
        "XCTAssertFalse": ("#expect", .exclamationMark),
        "XCTAssertNil": ("#expect", .equal),
        "XCTAssertNotNil": ("#expect", .notEqual),
        "XCTUnwrap": ("#require", nil),
        "XCTFail": ("Issue.record", nil)
    ]
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Check if this is a function call to any of our supported assertions
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              let assertInfo = assertions[identifierExpr.baseName.text] else {
            return ExprSyntax(node)
        }
        var arguments = node.arguments.filter { $0.label == nil }

        guard arguments.count >= 1 else {
            let newFunctionCall = node
                .with(\.arguments, arguments)
                .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(assertInfo.replacement))))
            return ExprSyntax(newFunctionCall)
        }
        
        let firstArg = arguments[arguments.startIndex]
        
        if assertInfo.operatorType == .exclamationMark,
           let token = assertInfo.operatorType?.token {
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
                operator: token,
                expression: newExpression
            )
            
            arguments[arguments.startIndex].expression = ExprSyntax(newArg)
        } else if let operatorType = assertInfo.operatorType {
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
            .with(\.calledExpression, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(assertInfo.replacement))))
            .with(\.leadingTrivia, node.leadingTrivia)

        return ExprSyntax(newFunctionCall)
    }
}
