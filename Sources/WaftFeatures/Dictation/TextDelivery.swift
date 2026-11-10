import WaftCore

struct TextDelivery {
    enum Outcome {
        case pasted
        case copied
        case keptOutOfPasswordField

        func message(showing text: String, detail: String? = nil) -> HUDMessage {
            switch self {
            case .pasted: HUDMessage(kind: .pasted, title: text, detail: detail)
            case .copied: HUDMessage(kind: .copied, title: text, detail: detail)
            case .keptOutOfPasswordField: .keptOutOfPasswordField(text)
            }
        }
    }

    let inserter: any TextInserter
    let clipboard: any Clipboard

    func deliver(_ text: String, into target: FocusTarget, releasing key: PushToTalkKey) async -> Outcome {
        switch await inserter.insert(text, into: target, releasing: key) {
        case .pasted:
            return .pasted

        case .skipped(.secureField):
            clipboard.copy(text)

            return .keptOutOfPasswordField

        case .skipped:
            clipboard.copy(text)

            return .copied
        }
    }

    func copy(_ text: String) -> Outcome {
        clipboard.copy(text)

        return .copied
    }
}
