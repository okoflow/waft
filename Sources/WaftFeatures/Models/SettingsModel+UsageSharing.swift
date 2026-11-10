import WaftCore

extension SettingsModel {
    var sharesUsage: Bool {
        get { settings.usageSharing == .allowed }
        set { settings.usageSharing = newValue ? .allowed : .declined }
    }
}
