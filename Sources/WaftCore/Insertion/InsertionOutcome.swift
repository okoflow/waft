package enum InsertionOutcome: Equatable, Sendable {
    case pasted
    case skipped(InsertionSkipReason)
}
