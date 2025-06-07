import SwiftSyntax

// MARK: - Strategy Protocol

protocol RewritingStrategy {
    func transformClass(_ node: ClassDeclSyntax, context: RewriterContext) -> DeclSyntax
    func transformFunction(_ node: FunctionDeclSyntax, context: RewriterContext) -> FunctionDeclSyntax
    func transformVariable(_ node: VariableDeclSyntax, context: RewriterContext) -> VariableDeclSyntax
}

// MARK: - Context

struct RewriterContext {
    let storedProperties: Set<String>
    let methods: Set<String>
    let hasTearDownMethod: Bool
    let inheritanceFromXCTestCase: Bool
}

// MARK: - Main Rewriter Class

final class ClassRewriter: SyntaxRewriter {
    private let strategy: any RewritingStrategy

    private var storedProperties: Set<String> = []
    private var methods: Set<String> = []
    private var hasTearDownMethod = false

    init(useClass: Bool) {
        self.strategy =
            if useClass {
                ClassStrategy()
            } else {
                StructStrategy()
            }
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        hasTearDownMethod = false

        let (processedNode, inheritanceFromXCTestCase) = processInheritanceClause(node)
        guard inheritanceFromXCTestCase else {
            return DeclSyntax(node)
        }

        storedProperties = collectStoredProperties(from: processedNode)
        methods = collectMethods(from: processedNode)

        let nodeWithUpdatedMembers = updateMemberFunctions(processedNode)

        let context = RewriterContext(
            storedProperties: storedProperties,
            methods: methods,
            hasTearDownMethod: hasTearDownMethod,
            inheritanceFromXCTestCase: inheritanceFromXCTestCase
        )

        return strategy.transformClass(nodeWithUpdatedMembers, context: context)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if node.isSetupMethod {
            return DeclSyntax(node.convertToInit())
        }

        if node.isTearDownMethod {
            hasTearDownMethod = true
            return DeclSyntax(node.convertToDeinit())
        }

        guard node.isTestFunction, !node.hasTestAttribute else {
            return DeclSyntax(node)
        }

        let context = RewriterContext(
            storedProperties: storedProperties,
            methods: methods,
            hasTearDownMethod: hasTearDownMethod,
            inheritanceFromXCTestCase: true
        )

        let nodeWithTestAttribute = node.addingTestAttribute()
        return DeclSyntax(strategy.transformFunction(nodeWithTestAttribute, context: context))
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let context = RewriterContext(
            storedProperties: storedProperties,
            methods: methods,
            hasTearDownMethod: hasTearDownMethod,
            inheritanceFromXCTestCase: true
        )

        return DeclSyntax(strategy.transformVariable(node, context: context))
    }

    private func updateMemberFunctions(_ node: ClassDeclSyntax) -> ClassDeclSyntax {
        var modifiedNode = node

        let updatedMembers = node.memberBlock.members.map { member in
            var updatedMember = member
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                updatedMember.decl = visit(funcDecl)
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                updatedMember.decl = visit(varDecl)
            }
            return updatedMember
        }

        modifiedNode.memberBlock.members = MemberBlockItemListSyntax(updatedMembers)
        return modifiedNode
    }
}

// MARK: - Class Strategy

struct ClassStrategy: RewritingStrategy {
    func transformClass(_ node: ClassDeclSyntax, context: RewriterContext) -> DeclSyntax {
        DeclSyntax(node)
    }

    func transformFunction(_ node: FunctionDeclSyntax, context: RewriterContext) -> FunctionDeclSyntax {
        node.addingSelfPrefixes(context: context)
    }

    func transformVariable(_ node: VariableDeclSyntax, context: RewriterContext) -> VariableDeclSyntax {
        node
    }
}

// MARK: - Struct Strategy

struct StructStrategy: RewritingStrategy {
    func transformClass(_ node: ClassDeclSyntax, context: RewriterContext) -> DeclSyntax {
        DeclSyntax(node.convertingToStruct(context: context))
    }

    func transformFunction(_ node: FunctionDeclSyntax, context: RewriterContext) -> FunctionDeclSyntax {
        let withoutOverride = node.with(\.modifiers, node.modifiers.filteringOverride())
        return withoutOverride.addingMutatingIfNeeded(context: context)
    }

    func transformVariable(_ node: VariableDeclSyntax, context: RewriterContext) -> VariableDeclSyntax {
        let filteredModifiers = node.modifiers.filteringOverride()
        return node.with(\.modifiers, filteredModifiers)
    }
}
