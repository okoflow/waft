package enum PermissionStatus: Sendable {
    case granted
    case denied
    case notDetermined

    package var isGranted: Bool {
        self == .granted
    }
}
