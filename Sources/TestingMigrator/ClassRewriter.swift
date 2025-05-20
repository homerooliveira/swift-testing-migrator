import SwiftSyntax

final class ClassRewriter: SyntaxRewriter {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        // Remove the inheritance clause
        var modifiedNode = node.with(\.inheritanceClause, nil)
        
        // Add the space after the class name
        modifiedNode = modifiedNode.with(\.name.trailingTrivia, .spaces(1))
        
        return DeclSyntax(modifiedNode)
    }
}
