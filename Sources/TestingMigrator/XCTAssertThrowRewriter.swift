import SwiftSyntax
import SwiftParser

final class XCTAssertThrowRewriter: SyntaxRewriter {

    let assertions: [String: String] = [
        "XCTAssertThrowsError": "(any Error).self",
        "XCTAssertNoThrow": "Never.self"
    ]

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let newNodes = node.flatMap { codeBlock in
             let visitedBlock = super.visit(codeBlock)

            if case .expr(let expression) = visitedBlock.item,
               let function = expression.as(FunctionCallExprSyntax.self) {
               return _visit(function)
            } else {
               return [visitedBlock]
            }
        }

        return CodeBlockItemListSyntax(newNodes)
    }

    func _visit(_ node: FunctionCallExprSyntax) -> [CodeBlockItemSyntax] {
        guard let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
              let errorType = assertions[identifierExpr.baseName.text] else {
            return [
                CodeBlockItemSyntax(
                    item: .expr(ExprSyntax(node))
                )
            ]
        }

        let arguments  = node.arguments.filter { $0.label == nil }

        guard arguments.count >= 1 else {
            return [
                CodeBlockItemSyntax(
                    item: .expr(ExprSyntax(node))
                )
            ]
        }

        let firstArgExpression = arguments[arguments.startIndex].expression

        var newFunctionCall = FunctionCallExprSyntax(
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

        var blockItems: [CodeBlockItemSyntax] = []

        let variable = VariableDeclSyntax(
            leadingTrivia: node.leadingTrivia,
            bindingSpecifier: .keyword(.let),
            bindings: PatternBindingListSyntax([
                PatternBindingListSyntax.Element(
                    pattern: IdentifierPatternSyntax(identifier: .identifier("error", leadingTrivia: .space, trailingTrivia: .space)),
                    initializer: InitializerClauseSyntax(equal: .equalToken(trailingTrivia: .space), value: ExprSyntax(newFunctionCall))
                )
            ])
        )

        blockItems.append(
            CodeBlockItemSyntax(
                item: .decl(DeclSyntax(variable))
            )
        )

        if let trailingClosure = node.trailingClosure {
            let parameter = trailingClosure.signature?.parameterClause.flatMap(unwrapClosureParameter(_:)) ?? "$0"

            blockItems.append(contentsOf: trailingClosure.statements.map { (statement: CodeBlockItemListSyntax.Element) in
                updateMemberAccessIfNeeded(
                    statement,
                    leadingTrivia: node.leadingTrivia,
                    trailingTrivia: node.trailingTrivia,
                    parameter: parameter
                )
            })
        }

        return blockItems
    }

    func unwrapClosureParameter(_ parameter: ClosureSignatureSyntax.ParameterClause) -> String? {
        switch parameter {
            case .simpleInput(let parameters):
                parameters.first?.name.trimmed.description
            case .parameterClause(let parameters):
                parameters.parameters.first?.firstName.trimmed.description
        }
    }

    func updateMemberAccessIfNeeded(
        _ statement: CodeBlockItemListSyntax.Element,
        leadingTrivia: Trivia,
        trailingTrivia: Trivia,
        parameter: String
    ) -> CodeBlockItemListSyntax.Element {
        let space = leadingTrivia.first { $0.isSpaceOrTab } ?? .spaces(0)
        let newTrivia = Trivia(pieces: [.newlines(1), space])

        if case .expr(let expression) = statement.item,
           let function = expression.as(FunctionCallExprSyntax.self) {
            let newArguments = function.arguments.map { label in
                guard let member = label.expression.as(MemberAccessExprSyntax.self) else {
                    return label
                }

                let currentName = member.base?.trimmed.description ?? "$0"

                guard currentName == parameter else {
                    return label
                }

                let newMember = member.with(\.base, ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("error?"))))

                return label.with(\.expression, ExprSyntax(newMember))
            }

            return statement
                .with(\.item, .expr(ExprSyntax(function.with(\.arguments, LabeledExprListSyntax(newArguments)))))
                .with(\.leadingTrivia, newTrivia)
        } else {
            return statement.with(\.leadingTrivia, newTrivia)
        }
    }
}
