import SwiftSyntax
import SwiftParser

final class XCTAssertThrowRewriter: SyntaxRewriter {

    let assertions: [String: String] = [
        "XCTAssertThrowsError": "(any Error).self",
        "XCTAssertNoThrow": "Never.self"
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              let errorType = assertions[identifierExpr.baseName.text] else {
            return ExprSyntax(node)
        }

        let arguments  = node.arguments.filter { $0.label == nil }

        guard arguments.count >= 1 else {
            return ExprSyntax(node)
        }

        let firstArgExpression = arguments[arguments.startIndex].expression

        var newFunctionCall = FunctionCallExprSyntax(
            leadingTrivia: node.leadingTrivia,
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier("#expect")),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(
                [
                    LabeledExprSyntax(
                        label: .identifier("throws"),
                        colon: .colonToken(),
                        expression: DeclReferenceExprSyntax(
                            baseName: .identifier(errorType)
                                .with(\.leadingTrivia, .space)
                        )
                    )
                ]
            ),
            rightParen: .rightParenToken(trailingTrivia: .space),
            trailingClosure: ClosureExprSyntax(
                statements: CodeBlockItemListSyntax(
                    [
                        CodeBlockItemSyntax(
                            item: .expr(firstArgExpression
                                .with(\.leadingTrivia, .space)
                                .with(\.trailingTrivia, .space))
                        )
                    ],
                )
            )
        )
        
        if arguments.count > 1 {
            newFunctionCall.arguments[newFunctionCall.arguments.startIndex].trailingComma = .commaToken(trailingTrivia: .space)
            var message = arguments[arguments.index(after: arguments.startIndex)]
            message.trailingComma = nil
            newFunctionCall.arguments.append(message)
        }

        return ExprSyntax(newFunctionCall)
    }
}
