import SwiftSyntax

extension ClassDeclSyntax {
    func convertingToStruct(context: RewriterContext) -> StructDeclSyntax {
        let filteredModifiers = modifiers.filteringInvalidForStruct()
        let inheritanceClause = createInheritanceClauseForStruct(context: context)
        let nameTrivia: Trivia = inheritanceClause == nil ? .space : []
        let structName = name.with(\.leadingTrivia, .space).with(\.trailingTrivia, nameTrivia)
        return StructDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifiers: filteredModifiers,
            name: structName,
            genericParameterClause: genericParameterClause,
            inheritanceClause: inheritanceClause,
            genericWhereClause: genericWhereClause,
            memberBlock: memberBlock,
            trailingTrivia: trailingTrivia
        )
    }

    private func createInheritanceClauseForStruct(context: RewriterContext) -> InheritanceClauseSyntax? {
        var inheritedTypes: [InheritedTypeSyntax] = []
        if let existingTypes = inheritanceClause?.inheritedTypes {
            inheritedTypes = Array(existingTypes.filter { $0.type.trimmedDescription != "XCTestCase" })
        }
        if context.hasTearDownMethod {
            let suppressedType = SuppressedTypeSyntax(
                withoutTilde: .prefixOperator("~"),
                type: IdentifierTypeSyntax(name: .identifier("Copyable"))
            )
            inheritedTypes.append(InheritedTypeSyntax(type: TypeSyntax(suppressedType)))
        }
        guard !inheritedTypes.isEmpty else { return nil }
        inheritedTypes[0] = inheritedTypes[0].with(\.leadingTrivia, .space)
        return InheritanceClauseSyntax(
            colon: .colonToken().with(\.leadingTrivia, []).with(\.trailingTrivia, .space),
            inheritedTypes: InheritedTypeListSyntax(inheritedTypes.map { $0.with(\.leadingTrivia, []) }),
            trailingTrivia: .space
        )
    }
}
