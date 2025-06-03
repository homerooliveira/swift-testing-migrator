import SwiftSyntax

final class ClassRewriter: SyntaxRewriter {
    private let useClass: Bool
    private var storedProperties: Set<String> = []
    private var methods: Set<String> = []
    private let setupMethods: Set<String> = ["setUp", "setUpWithError"]

    init(useClass: Bool) {
        self.useClass = useClass
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let (processedNode, inheritanceFromXCTestCase) = processInheritanceClause(node)
        guard inheritanceFromXCTestCase else {
            return DeclSyntax(node)
        }

        // Collect stored properties and methods before processing members
        storedProperties = collectStoredProperties(from: processedNode)
        methods = collectMethods(from: processedNode)

        let nodeWithUpdatedMembers = updateMemberFunctions(processedNode)

        if useClass {
            return DeclSyntax(nodeWithUpdatedMembers)
        } else {
            return DeclSyntax(convertToStruct(nodeWithUpdatedMembers))
        }
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

    private func collectStoredProperties(from node: ClassDeclSyntax) -> Set<String> {
        var properties: Set<String> = []

        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check if it's a stored property (not computed)
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                       binding.accessorBlock == nil { // No accessor block means stored property
                        properties.insert(identifier.identifier.text)
                    }
                }
            }
        }

        return properties
    }

    private func collectMethods(from node: ClassDeclSyntax) -> Set<String> {
        var methods: Set<String> = []

        for member in node.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                methods.insert(funcDecl.name.text)
            }
        }

        return methods
    }

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
        return setupMethods.contains(node.name.text)
    }

    private func convertSetupToInit(_ node: FunctionDeclSyntax) -> InitializerDeclSyntax {
        // Remove override and other invalid modifiers for init
        let filteredModifiers = filterModifiersForInit(node.modifiers)

        // Remove super.setUp() calls when converting to init
        let processedBody = removeSuperSetupCalls(from: node.body)

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
            body: processedBody,
            trailingTrivia: node.trailingTrivia
        )
    }

    private func removeSuperSetupCalls(from body: CodeBlockSyntax?) -> CodeBlockSyntax? {
        guard let body = body else { return nil }

        let rewriter = SuperMethodsRemover(methods: setupMethods)
        return rewriter.rewrite(body).as(CodeBlockSyntax.self) ?? body
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

        // Add self prefixes to the body when converting to class
        let processedBody = node.body

        let modifiedNode = node
            .with(\.attributes, updatedAttributes)
            .with(\.funcKeyword.leadingTrivia, .space)
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.body, processedBody)

        // Remove override modifier if converting to struct and it's not a test function being kept as class
        if useClass {
            return modifiedNode
        } else {
            return removeOverrideModifier(from: modifiedNode)
        }
    }

    private func processFunctionForStructConversion(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let processedDecl = visit(node)

        // If visit() converted it to an InitializerDeclSyntax, return it as-is
        if processedDecl.is(InitializerDeclSyntax.self) {
            return processedDecl
        }

        // Otherwise, it's still a FunctionDeclSyntax, so handle override modifier removal and mutating
        let processedForTest = processedDecl.as(FunctionDeclSyntax.self) ?? node

        if useClass {
            // Add self prefixes when converting to class
            let withSelfPrefixes = addSelfPrefixesToFunction(processedForTest)
            return DeclSyntax(withSelfPrefixes)
        } else {
            let withoutOverride = removeOverrideModifier(from: processedForTest)
            return DeclSyntax(addMutatingIfNeeded(to: withoutOverride))
        }
    }

    private func removeOverrideModifier(from node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        let filteredModifiers = filterOverrideModifier(node.modifiers)
        return node.with(\.modifiers, filteredModifiers)
    }

    private func addMutatingIfNeeded(to node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        // Only add mutating when converting to struct, not when keeping as class
        guard !useClass else {
            return node
        }

        // Skip if already has mutating modifier
        let hasMutating = node.modifiers.contains { $0.name.tokenKind == .keyword(.mutating) }

        guard !hasMutating else {
            return node
        }

        // Check if function body accesses stored properties in a potentially mutating way
        guard let body = node.body,
              functionAccessesStoredProperties(body: body) else {
            return node
        }

        let leadingTrivia = if node.attributes.isEmpty {
            node.leadingTrivia
        } else {
            Trivia.space
        }

        // Add mutating modifier
        let mutatingModifier = DeclModifierSyntax(
            leadingTrivia: leadingTrivia,
            name: .keyword(.mutating)
        )

        var updatedModifiers = node.modifiers
        updatedModifiers.append(mutatingModifier)

        return node.with(\.modifiers, updatedModifiers)
            .with(\.funcKeyword.leadingTrivia, .space)
    }

    private func functionAccessesStoredProperties(body: CodeBlockSyntax) -> Bool {
        let visitor = PropertyAccessVisitor(storedProperties: storedProperties)
        visitor.walk(body)
        return visitor.accessesStoredProperty
    }

    private func addSelfPrefixesToFunction(_ node: FunctionDeclSyntax) -> FunctionDeclSyntax {
        guard let body = node.body else {
            return node
        }

        let rewriter = SelfPrefixRewriter(
            storedProperties: storedProperties,
            methods: methods
        )

        let processedBody = rewriter.rewrite(body).as(CodeBlockSyntax.self) ?? body

        return node.with(\.body, processedBody)
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
