import SwiftSyntax

extension DeclModifierListSyntax {
    func filteringOverride() -> DeclModifierListSyntax {
        filter { $0.name.tokenKind != .keyword(.override) }
    }

    func filteringInvalidForInit() -> DeclModifierListSyntax {
        let invalidModifiers: Set<TokenKind> = [
            .keyword(.override), .keyword(.final), .keyword(.open), .keyword(.convenience)
        ]
        return filter { !invalidModifiers.contains($0.name.tokenKind) }
    }

    func filteringInvalidForStruct() -> DeclModifierListSyntax {
        let invalidModifiers: Set<TokenKind> = [.keyword(.open), .keyword(.final)]
        return filter { !invalidModifiers.contains($0.name.tokenKind) }
    }

    var hasMutating: Bool {
        contains { $0.name.tokenKind == .keyword(.mutating) }
    }
}
