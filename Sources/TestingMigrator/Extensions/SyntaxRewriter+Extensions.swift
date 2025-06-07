import SwiftSyntax

extension SyntaxRewriter {
    func collectStoredProperties(from node: ClassDeclSyntax) -> Set<String> {
        var properties: Set<String> = []
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                       binding.accessorBlock == nil {
                        properties.insert(identifier.identifier.text)
                    }
                }
            }
        }
        return properties
    }

    func collectMethods(from node: ClassDeclSyntax) -> Set<String> {
        var methods: Set<String> = []
        for member in node.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                methods.insert(funcDecl.name.text)
            }
        }
        return methods
    }

    func processInheritanceClause(_ node: ClassDeclSyntax) -> (ClassDeclSyntax, Bool) {
        var modifiedNode = node
        guard let originalTypes = node.inheritanceClause?.inheritedTypes else {
            return (modifiedNode, false)
        }
        var filteredTypes = originalTypes.filter { $0.type.trimmedDescription != "XCTestCase" }
        if filteredTypes.isEmpty {
            modifiedNode.inheritanceClause = nil
            modifiedNode.name.trailingTrivia = .space
        } else {
            if !filteredTypes.isEmpty {
                filteredTypes[filteredTypes.startIndex] = filteredTypes[filteredTypes.startIndex].with(\.leadingTrivia, .space)
            }
            modifiedNode.inheritanceClause = InheritanceClauseSyntax(inheritedTypes: filteredTypes)
        }
        return (modifiedNode, filteredTypes.count != originalTypes.count)
    }
}
