import SwiftSyntax

final class ClassRewriter: SyntaxRewriter {
    let useClass: Bool

    init(useClass: Bool) {
        self.useClass = useClass
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var node = node
        guard var inheritedTypes = (node.inheritanceClause?.inheritedTypes.filter { $0.type.trimmedDescription != "XCTestCase" }) else {
            return DeclSyntax(node)
        }
        
        if !inheritedTypes.isEmpty {
            inheritedTypes[inheritedTypes.startIndex].leadingTrivia = .space
            node.inheritanceClause = InheritanceClauseSyntax(inheritedTypes: inheritedTypes)
        } else {
            node.inheritanceClause = nil
            node.name.trailingTrivia = .space
        }
        
        let newMembers = node.memberBlock.members.map { member in
            var member = member
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                member.decl = _visit(funcDecl)
            }
            return member
        }

        node.memberBlock.members = MemberBlockItemListSyntax(newMembers)

        // node.name = TokenSyntax.identifier("_" + node.name.text)
        if useClass {
            return DeclSyntax(node)
        } else {
            let removeModifiers: Set<TokenKind> = [.keyword(.open), .keyword(.final)]
            let newModifiers = node.modifiers.filter { 
                !removeModifiers.contains($0.name.tokenKind) 
            }

            let structDecl = StructDeclSyntax(
                leadingTrivia: node.leadingTrivia, 
                attributes: node.attributes,
                modifiers: newModifiers, 
                name: node.name.with(\.leadingTrivia, .space), 
                genericParameterClause: node.genericParameterClause, 
                inheritanceClause: node.inheritanceClause, 
                genericWhereClause: node.genericWhereClause, 
                memberBlock: node.memberBlock, 
                trailingTrivia: node.trailingTrivia
            )
            return DeclSyntax(structDecl)
        }   
    }
    
    func _visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard node.name.text.hasPrefix("test") else {
            return DeclSyntax(node)
        }
        
        let testAttribute = AttributeSyntax(
            leadingTrivia: [], // No leading trivia
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
            leftParen: nil,
            arguments: nil,
            rightParen: nil
        )
        
        var attributes = node.attributes
        
        if attributes.contains(where: {
            $0.as(AttributeSyntax.self)?.attributeName.trimmed.description == "Test"
        }) {
            return DeclSyntax(node)
        }
        
        attributes.append(AttributeListSyntax.Element(testAttribute))
        
        let newFunction = node.with(\.attributes, attributes)
            .with(\.funcKeyword.leadingTrivia, .space)
            .with(\.leadingTrivia, node.leadingTrivia)
        
        return DeclSyntax(newFunction)
    }
}
