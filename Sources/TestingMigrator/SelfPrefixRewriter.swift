import SwiftSyntax

final class SelfPrefixRewriter: SyntaxRewriter {
    private let storedProperties: Set<String>
    private let methods: Set<String>
    private var localVariables: Set<String> = []
    private var parameters: Set<String> = []
    private var insideClosure = false
    
    init(storedProperties: Set<String>, methods: Set<String>) {
        self.storedProperties = storedProperties
        self.methods = methods
    }
    
    // MARK: - Main Expression Handling
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        let identifier = node.baseName.text
        
        guard insideClosure && shouldAddSelfPrefix(for: identifier) else {
            return ExprSyntax(node)
        }
        
        return ExprSyntax(createSelfMemberAccess(for: identifier, originalNode: node))
    }
    
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        // Don't modify if already has self prefix
        if isAlreadySelfPrefixed(node) {
            return ExprSyntax(node)
        }
        
        // Check if this is a root member access that needs self prefix
        if insideClosure, let baseExpr = node.base?.as(DeclReferenceExprSyntax.self) {
            let baseIdentifier = baseExpr.baseName.text
            if shouldAddSelfPrefix(for: baseIdentifier) {
                // Create self.baseIdentifier.memberName
                let selfBase = createSelfMemberAccess(for: baseIdentifier, originalNode: baseExpr)
                return ExprSyntax(node.with(\.base, ExprSyntax(selfBase)))
            }
        }
        
        // Process the base expression recursively
        return ExprSyntax(node.with(\.base, node.base.map { visit($0) }))
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        let processedArguments = processArguments(node.arguments)
        
        guard insideClosure else {
            return handleFunctionCallOutsideClosure(node, processedArguments: processedArguments)
        }
        
        return handleFunctionCallInsideClosure(node, processedArguments: processedArguments)
    }
    
    override func visit(_ node: TryExprSyntax) -> ExprSyntax {
        return ExprSyntax(node.with(\.expression, visit(node.expression)))
    }
    
    // MARK: - Closure Handling
    
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        return withClosureContext {
            extractClosureParameters(from: node.signature)
            let processedStatements = node.statements.map { visit($0) }
            return node.with(\.statements, CodeBlockItemListSyntax(processedStatements))
        }
    }
    
    // MARK: - Variable and Scope Tracking
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        trackLocalVariables(from: node.bindings)
        let processedBindings = processVariableBindings(node.bindings)
        return DeclSyntax(node.with(\.bindings, PatternBindingListSyntax(processedBindings)))
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        return withLocalVariableScope {
            trackPatternVariable(node.pattern)
            let processedBody = visit(node.body)
            return StmtSyntax(node.with(\.body, processedBody))
        }
    }
    
    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        trackOptionalBindings(from: node.conditions)
        return super.visit(node)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        return withLocalVariableScope {
            trackOptionalBindings(from: node.conditions)
            return super.visit(node)
        }
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        // Don't process nested functions - they maintain their own scope
        DeclSyntax(node)
    }
    
    // MARK: - Helper Methods
    
    private func shouldAddSelfPrefix(for identifier: String) -> Bool {
        !localVariables.contains(identifier) && 
               !parameters.contains(identifier) && 
               (storedProperties.contains(identifier) || methods.contains(identifier))
    }
    
    private func isAlreadySelfPrefixed(_ node: MemberAccessExprSyntax) -> Bool {
        guard let baseExpr = node.base?.as(DeclReferenceExprSyntax.self) else { return false }
        return baseExpr.baseName.text == "self"
    }
    
    private func processArguments(_ arguments: LabeledExprListSyntax) -> [LabeledExprSyntax] {
        arguments.map { argument in
            argument.with(\.expression, visit(argument.expression))
        }
    }
    
    private func handleFunctionCallOutsideClosure(_ node: FunctionCallExprSyntax, processedArguments: [LabeledExprSyntax]) -> ExprSyntax {
        var updatedNode = node.with(\.arguments, LabeledExprListSyntax(processedArguments))
        
        if let trailingClosure = node.trailingClosure,
           let newTrailingClosure = visit(trailingClosure).as(ClosureExprSyntax.self) {
            updatedNode = updatedNode.with(\.trailingClosure, newTrailingClosure)
        }
        
        return ExprSyntax(updatedNode)
    }
    
    private func handleFunctionCallInsideClosure(_ node: FunctionCallExprSyntax, processedArguments: [LabeledExprSyntax]) -> ExprSyntax {
        var updatedNode = node.with(\.arguments, LabeledExprListSyntax(processedArguments))
        
        // First process the called expression to handle member access chains
        let processedCalledExpression = visit(node.calledExpression)
        updatedNode = updatedNode.with(\.calledExpression, processedCalledExpression)
        
        // Handle trailing closure if present
        if let trailingClosure = node.trailingClosure,
           let newTrailingClosure = visit(trailingClosure).as(ClosureExprSyntax.self) {
            updatedNode = updatedNode.with(\.trailingClosure, newTrailingClosure)
        }
        
        return ExprSyntax(updatedNode)
    }
    
    private func handleMemberAccessMethodCall(_ node: FunctionCallExprSyntax, memberAccess: MemberAccessExprSyntax) -> FunctionCallExprSyntax {
        // If it's a direct method call without base (implicitly on self)
        if memberAccess.base == nil && methods.contains(memberAccess.declName.baseName.text) {
            let selfMemberAccess = createSelfMemberAccess(
                for: memberAccess.declName.baseName.text,
                originalNode: memberAccess
            )
            return node.with(\.calledExpression, ExprSyntax(selfMemberAccess))
        }
        return node
    }
    
    private func handleDirectMethodCall(_ node: FunctionCallExprSyntax, declRef: DeclReferenceExprSyntax) -> FunctionCallExprSyntax {
        if methods.contains(declRef.baseName.text) {
            let selfMemberAccess = createSelfMemberAccess(
                for: declRef.baseName.text,
                originalNode: declRef
            )
            return node.with(\.calledExpression, ExprSyntax(selfMemberAccess))
        }
        return node
    }
    
    // MARK: - Context Management
    
    private func withClosureContext(_ action: () -> some ExprSyntaxProtocol) -> ExprSyntax {
        let wasInsideClosure = insideClosure
        let originalLocalVars = localVariables
        let originalParameters = parameters
        
        insideClosure = true
        defer {
            insideClosure = wasInsideClosure
            localVariables = originalLocalVars
            parameters = originalParameters
        }
        
        return ExprSyntax(action())
    }
    
    private func withLocalVariableScope<T>(_ action: () -> T) -> T where T: SyntaxProtocol {
        let originalLocalVars = localVariables
        defer { localVariables = originalLocalVars }
        return action()
    }
    
    // MARK: - Variable Tracking
    
    private func extractClosureParameters(from signature: ClosureSignatureSyntax?) {
        guard let signature = signature,
              let parameterClause = signature.parameterClause else { return }
        
        switch parameterClause {
        case .parameterClause(let clause):
            for parameter in clause.parameters {
                parameters.insert(parameter.firstName.text)
                if let secondName = parameter.secondName {
                    parameters.insert(secondName.text)
                }
            }
        case .simpleInput(let clause):
            for parameter in clause {
                parameters.insert(parameter.name.text)
            }
        }
    }
    
    private func trackLocalVariables(from bindings: PatternBindingListSyntax) {
        for binding in bindings {
            trackPatternVariable(binding.pattern)
        }
    }
    
    private func trackPatternVariable(_ pattern: PatternSyntax) {
        if let identifier = pattern.as(IdentifierPatternSyntax.self) {
            localVariables.insert(identifier.identifier.text)
        }
    }
    
    private func processVariableBindings(_ bindings: PatternBindingListSyntax) -> [PatternBindingSyntax] {
        return bindings.map { binding in
            guard let initializer = binding.initializer else { return binding }
            let processedInitializer = initializer.with(\.value, visit(initializer.value))
            return binding.with(\.initializer, processedInitializer)
        }
    }
    
    private func trackOptionalBindings(from conditions: ConditionElementListSyntax) {
        for condition in conditions {
            if let bindingCondition = condition.condition.as(OptionalBindingConditionSyntax.self) {
                trackPatternVariable(bindingCondition.pattern)
            }
        }
    }
    
    private func createSelfMemberAccess(for identifier: String, originalNode: any SyntaxProtocol) -> MemberAccessExprSyntax {
        let selfExpr = DeclReferenceExprSyntax(baseName: .identifier("self"))
        
        return MemberAccessExprSyntax(
            leadingTrivia: originalNode.leadingTrivia,
            base: ExprSyntax(selfExpr),
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(identifier)),
            trailingTrivia: originalNode.trailingTrivia
        )
    }
}