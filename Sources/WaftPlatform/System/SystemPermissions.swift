package import WaftCore
import AppKit
import ApplicationServices
import AVFoundation
import os

@MainActor
package final class SystemPermissions: PermissionProvider {
    private var hasPromptedForAccessibility = false

    package init() {}

    package func status(of permission: Permission) -> PermissionStatus {
        switch permission {
        case .microphone:
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .notDetermined: .notDetermined
            case .restricted, .denied: .denied
            case .authorized: .granted
            @unknown default: .denied
            }

        case .accessibility:
            AXIsProcessTrusted() ? .granted : .denied
        }
    }

    package func request(_ permission: Permission) async {
        switch permission {
        case .microphone where status(of: .microphone) == .notDetermined:
            _ = await AVCaptureDevice.requestAccess(for: .audio)

        case .accessibility where !hasPromptedForAccessibility:
            hasPromptedForAccessibility = true
            _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)

        case .microphone, .accessibility:
            openSystemSettings(for: permission)
        }
    }

    private func openSystemSettings(for permission: Permission) {
        let pane =
            switch permission {
            case .microphone: URL(literal: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
            case .accessibility: URL(literal: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }

        guard !NSWorkspace.shared.open(pane) else { return }

        let name = String(describing: permission)

        Logger.system.error("Couldn't open System Settings for the \(name, privacy: .public) permission")
    }
}
