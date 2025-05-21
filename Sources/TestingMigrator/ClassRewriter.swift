import SwiftSyntax

final class ClassRewriter: SyntaxRewriter {
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
        
        return DeclSyntax(node.with(\.memberBlock.members, MemberBlockItemListSyntax(newMembers)))
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
        
        // Get existing attributes or create empty list
        let existingAttributes = node.attributes
        
        if existingAttributes.contains(where: {
            $0.as(AttributeSyntax.self)?.attributeName.trimmed.description == "Test"
        }) {
            return DeclSyntax(node)
        }
        
        // Create a new attribute list with all existing attributes plus the new one
        let newAttributeElements = existingAttributes + [AttributeListSyntax.Element(testAttribute)]
        
        // Preserve the leading trivia from the original function
        let originalLeadingTrivia = node.leadingTrivia
        
        // Create a new function with the updated attributes
        var newFunction = node.with(\.attributes, newAttributeElements)
        
        // Make sure the function keyword has a space after the @Test
        newFunction = newFunction.with(\.funcKeyword,
                                        newFunction.funcKeyword.with(\.leadingTrivia, .space))
        
        // Restore the original leading trivia to the function
        newFunction = newFunction.with(\.leadingTrivia, originalLeadingTrivia)
        
        return DeclSyntax(newFunction)
    }
}
