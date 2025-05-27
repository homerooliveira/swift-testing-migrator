import SwiftSyntax

final class ClassRewriter: SyntaxRewriter {
    private let useClass: Bool
    
    init(useClass: Bool) {
        self.useClass = useClass
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let (processedNode, inheritanceFromXCTestCase) = processInheritanceClause(node)
        guard inheritanceFromXCTestCase else {
            return DeclSyntax(node)
        }

        let nodeWithUpdatedMembers = updateMemberFunctions(processedNode)
        
        return useClass 
            ? DeclSyntax(nodeWithUpdatedMembers)
            : DeclSyntax(convertToStruct(nodeWithUpdatedMembers))
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if isSetupMethod(node) {
            return DeclSyntax(convertSetupToInit(node))
        }
        
        guard isTestFunction(node), !hasTestAttribute(node) else {
            return DeclSyntax(node)
        }
        
        return DeclSyntax(addTestAttribute(to: node))
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard !useClass else {
            return DeclSyntax(node)
        }
        
        // Remove override keyword from variables when converting to struct
        let filteredModifiers = filterOverrideModifier(node.modifiers)
        return DeclSyntax(node.with(\.modifiers, filteredModifiers))
    }
    
    // MARK: - Private Methods
    
    private func processInheritanceClause(_ node: ClassDeclSyntax) -> (ClassDeclSyntax, Bool) {
        var modifiedNode = node
        
        guard let originalTypes = node.inheritanceClause?.inheritedTypes else {
            return (modifiedNode, false)
        }
        
        let filteredTypes = originalTypes.filter { $0.type.trimmedDescription != "XCTestCase" }

        if filteredTypes.isEmpty {
            modifiedNode.inheritanceClause = nil
            modifiedNode.name.trailingTrivia = .space
        } else {
            var updatedTypes = filteredTypes
            updatedTypes[updatedTypes.startIndex].leadingTrivia = .space
            modifiedNode.inheritanceClause = InheritanceClauseSyntax(inheritedTypes: updatedTypes)
        }
        
        return (modifiedNode, filteredTypes.count != originalTypes.count)
    }
    
    private func updateMemberFunctions(_ node: ClassDeclSyntax) -> ClassDeclSyntax {
        var modifiedNode = node
        
        let updatedMembers = node.memberBlock.members.map { member in
            var updatedMember = member
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                updatedMember.decl = processFunctionForStructConversion(funcDecl)
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                updatedMember.decl = visit(varDecl)
            }
            return updatedMember
        }
        
        modifiedNode.memberBlock.members = MemberBlockItemListSyntax(updatedMembers)
        return modifiedNode
    }
    
    private func convertToStruct(_ node: ClassDeclSyntax) -> StructDeclSyntax {
        let filteredModifiers = filterModifiersForStruct(node.modifiers)
        
        return StructDeclSyntax(
            leadingTrivia: node.leadingTrivia,
            attributes: node.attributes,
            modifiers: filteredModifiers,
            name: node.name.with(\.leadingTrivia, .space),
            genericParameterClause: node.genericParameterClause,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            memberBlock: node.memberBlock,
            trailingTrivia: node.trailingTrivia
        )
    }
    
    private func filterModifiersForStruct(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax {
        let invalidModifiers: Set<TokenKind> = [
            .keyword(.open), 
            .keyword(.final), 
            .keyword(.override),
            .keyword(.convenience)
        ]
        return modifiers.filter { !invalidModifiers.contains($0.name.tokenKind) }
    }
    
    private func filterOverrideModifier(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax {
        modifiers.filter { $0.name.tokenKind != .keyword(.override) }
    }
    
    private func isTestFunction(_ node: FunctionDeclSyntax) -> Bool {
        node.name.text.hasPrefix("test")
    }
    
    private func isSetupMethod(_ node: FunctionDeclSyntax) -> Bool {
        let setupMethods: Set<String> = ["setUp", "setUpWithError"]
        return setupMethods.contains(node.name.text)
    }
    
    private func convertSetupToInit(_ node: FunctionDeclSyntax) -> InitializerDeclSyntax {
        // Remove override and other invalid modifiers for init
        let filteredModifiers = filterModifiersForInit(node.modifiers)
        
        return InitializerDeclSyntax(
            leadingTrivia: node.leadingTrivia,
            attributes: node.attributes,
            modifiers: filteredModifiers,
            initKeyword: .keyword(.`init`),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    leftParen: node.signature.parameterClause.leftParen,
                    parameters: FunctionParameterListSyntax(),
                    rightParen: node.signature.parameterClause.rightParen
                ),
                effectSpecifiers: node.signature.effectSpecifiers
            ),
            body: node.body,
            trailingTrivia: node.trailingTrivia
        )
    }
    
    private func filterModifiersForInit(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax {
        let invalidModifiers: Set<TokenKind> = [
            .keyword(.override),
            .keyword(.final),
            .keyword(.open),
            .keyword(.convenience)
        ]
        return modifiers.filter { !invalidModifiers.contains($0.name.tokenKind) }
    }
    
    private func hasTestAttribute(_ node: FunctionDeclSyntax) -> Bool {
        node.attributes.contains { attribute in
            attribute.as(AttributeSyntax.self)?.attributeName.trimmed.description == "Test"
        }
    }
    
    private func addTestAttribute(to node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        let testAttribute = createTestAttribute()
        var updatedAttributes = node.attributes
        updatedAttributes.append(AttributeListSyntax.Element(testAttribute))
        
        let modifiedNode = node
            .with(\.attributes, updatedAttributes)
            .with(\.funcKeyword.leadingTrivia, .space)
            .with(\.leadingTrivia, node.leadingTrivia)
        
        // Remove override modifier if converting to struct and it's not a test function being kept as class
        return useClass ? modifiedNode : removeOverrideModifier(from: modifiedNode)
    }
    
    private func processFunctionForStructConversion(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let processedDecl = visit(node)
        
        // If visit() converted it to an InitializerDeclSyntax, return it as-is
        if processedDecl.is(InitializerDeclSyntax.self) {
            return processedDecl
        }
        
        // Otherwise, it's still a FunctionDeclSyntax, so handle override modifier removal
        let processedForTest = processedDecl.as(FunctionDeclSyntax.self) ?? node
        return useClass ? DeclSyntax(processedForTest) : DeclSyntax(removeOverrideModifier(from: processedForTest))
    }
    
    private func removeOverrideModifier(from node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        let filteredModifiers = filterOverrideModifier(node.modifiers)
        return node.with(\.modifiers, filteredModifiers)
    }
    
    private func createTestAttribute() -> AttributeSyntax {
        AttributeSyntax(
            leadingTrivia: [],
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
            leftParen: nil,
            arguments: nil,
            rightParen: nil
        )
    }
}