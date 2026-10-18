import SwiftUI
import WaftCore

struct PermissionStep: View {
    private static let groupsUnderDeviceControl = ProcessInfo.processInfo.isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0),
    )

    let permission: Permission
    let monitor: PermissionMonitor

    private var symbolName: String {
        switch permission {
        case .microphone: "mic.fill"
        case .accessibility: "accessibility"
        }
    }

    private var tint: TileTint {
        switch permission {
        case .microphone: .red
        case .accessibility: .blue
        }
    }

    private var title: LocalizedStringKey {
        switch permission {
        case .microphone: "Allow microphone access"
        case .accessibility: "Allow Accessibility access"
        }
    }

    private var showsDeviceControlHint: Bool {
        permission == .accessibility && Self.groupsUnderDeviceControl
    }

    private var message: LocalizedStringKey {
        switch permission {
        case .microphone:
            "Waft listens only while you dictate, and the audio stays on your Mac."
        case .accessibility:
            "Waft needs it to notice the key and paste your text. Turn on Waft in the list that opens."
        }
    }

    var body: some View {
        OnboardingStep(title: title, message: message) {
            IconTile(symbolName: symbolName, tint: tint, size: Metrics.heroTileSize)
        } content: {
            VStack(spacing: Metrics.groupSpacing) {
                SettingsCard {
                    PermissionRow(permission: permission, monitor: monitor, offersRequest: false)
                }

                if showsDeviceControlHint {
                    Text("On macOS 27, it's under Device Control and Data Access.")
                        .font(.rowDetail)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
    }
}
