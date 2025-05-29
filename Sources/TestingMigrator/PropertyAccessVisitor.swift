import SwiftSyntax

final class PropertyAccessVisitor: SyntaxVisitor {
    let storedProperties: Set<String>
    var accessesStoredProperty = false
    
    init(storedProperties: Set<String>) {
        self.storedProperties = storedProperties
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // Check for self.property or implicit property access
        if let baseExpr = node.base {
            // Check for explicit self access: self.propertyName
            if let declRefExpr = baseExpr.as(DeclReferenceExprSyntax.self),
               declRefExpr.baseName.text == "self",
               storedProperties.contains(node.declName.baseName.text) {
                accessesStoredProperty = true
                return .skipChildren
            }
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        // Check for implicit property access (just propertyName without self.)
        if storedProperties.contains(node.baseName.text) {
            // Additional check: ensure this isn't a local variable or parameter
            // This is a simplified check - in a real implementation, you'd want
            // to maintain a scope stack to properly distinguish between
            // stored properties and local variables
            accessesStoredProperty = true
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        // Check for assignment operations (= operator)
        if let operatorToken = node.operator.as(BinaryOperatorExprSyntax.self),
           operatorToken.operator.text == "=" {
            
            // Check if the left side is a stored property
            if let memberAccess = node.leftOperand.as(MemberAccessExprSyntax.self) {
                if let baseExpr = memberAccess.base?.as(DeclReferenceExprSyntax.self),
                   baseExpr.baseName.text == "self",
                   storedProperties.contains(memberAccess.declName.baseName.text) {
                    accessesStoredProperty = true
                    return .skipChildren
                }
            } else if let declRef = node.leftOperand.as(DeclReferenceExprSyntax.self),
                      storedProperties.contains(declRef.baseName.text) {
                accessesStoredProperty = true
                return .skipChildren
            }
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        // Check for inout usage of stored properties
        if let memberAccess = node.expression.as(MemberAccessExprSyntax.self) {
            if let baseExpr = memberAccess.base?.as(DeclReferenceExprSyntax.self),
               baseExpr.baseName.text == "self",
               storedProperties.contains(memberAccess.declName.baseName.text) {
                accessesStoredProperty = true
                return .skipChildren
            }
        } else if let declRef = node.expression.as(DeclReferenceExprSyntax.self),
                  storedProperties.contains(declRef.baseName.text) {
            accessesStoredProperty = true
            return .skipChildren
        }
        
        return .visitChildren
    }
}