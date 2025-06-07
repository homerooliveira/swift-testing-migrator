import SwiftSyntax

extension FunctionDeclSyntax {
    private static let setupMethods: Set<String> = ["setUp", "setUpWithError"]
    private static let tearDownMethods: Set<String> = ["tearDown", "tearDownWithError"]

    var isTestFunction: Bool {
        name.text.hasPrefix("test")
    }

    var isSetupMethod: Bool {
        Self.setupMethods.contains(name.text)
    }

    var isTearDownMethod: Bool {
        Self.tearDownMethods.contains(name.text)
    }

    var hasTestAttribute: Bool {
        attributes.contains { attribute in
            attribute.as(AttributeSyntax.self)?.attributeName.trimmed.description == "Test"
        }
    }

    func convertToInit() -> InitializerDeclSyntax {
        let filteredModifiers = modifiers.filteringInvalidForInit()
        let processedBody = body?.removingCalls(to: Self.setupMethods)
        return InitializerDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifiers: filteredModifiers,
            initKeyword: .keyword(.`init`),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    leftParen: signature.parameterClause.leftParen,
                    parameters: FunctionParameterListSyntax(),
                    rightParen: signature.parameterClause.rightParen
                ),
                effectSpecifiers: signature.effectSpecifiers
            ),
            body: processedBody,
            trailingTrivia: trailingTrivia
        )
    }

    func convertToDeinit() -> DeinitializerDeclSyntax {
        let processedBody = body?.removingCalls(to: Self.tearDownMethods)
        return DeinitializerDeclSyntax(
            leadingTrivia: leadingTrivia,
            attributes: attributes,
            modifiers: DeclModifierListSyntax(),
            deinitKeyword: .keyword(.deinit, trailingTrivia: .space),
            body: processedBody,
            trailingTrivia: trailingTrivia
        )
    }

    func addingTestAttribute() -> FunctionDeclSyntax {
        let testAttribute = AttributeSyntax(
            leadingTrivia: [],
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
            leftParen: nil,
            arguments: nil,
            rightParen: nil
        )
        var updatedAttributes = attributes
        updatedAttributes.append(AttributeListSyntax.Element(testAttribute))
        return
            self
            .with(\.attributes, updatedAttributes)
            .with(\.funcKeyword.leadingTrivia, .space)
            .with(\.leadingTrivia, leadingTrivia)
    }

    func addingSelfPrefixes(context: RewriterContext) -> FunctionDeclSyntax {
        guard let body = body else { return self }
        let rewriter = SelfPrefixRewriter(
            storedProperties: context.storedProperties,
            methods: context.methods
        )
        let processedBody = rewriter.rewrite(body).as(CodeBlockSyntax.self) ?? body
        return with(\.body, processedBody)
    }

    func accessesStoredProperties(context: RewriterContext) -> Bool {
        guard let body = body else { return false }
        let visitor = PropertyAccessVisitor(storedProperties: context.storedProperties)
        visitor.walk(body)
        return visitor.accessesStoredProperty
    }
}
