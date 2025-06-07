import SwiftSyntax

extension FunctionDeclSyntax {
    func addingMutatingIfNeeded(context: RewriterContext) -> FunctionDeclSyntax {
        guard !modifiers.hasMutating else { return self }
        guard accessesStoredProperties(context: context) else { return self }
        let leadingTrivia = attributes.isEmpty ? leadingTrivia : Trivia.space
        let mutatingModifier = DeclModifierSyntax(
            leadingTrivia: leadingTrivia,
            name: .keyword(.mutating)
        )
        var updatedModifiers = modifiers
        updatedModifiers.append(mutatingModifier)
        return self
            .with(\.modifiers, updatedModifiers)
            .with(\.funcKeyword.leadingTrivia, .space)
    }
}
