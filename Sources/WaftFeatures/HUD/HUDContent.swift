enum HUDContent: Equatable {
    case listening(badge: String, isHandsFree: Bool)
    case working(String)
    case message(HUDMessage)
}
