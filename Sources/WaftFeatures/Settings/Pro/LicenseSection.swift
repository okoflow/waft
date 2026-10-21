import SwiftUI
import WaftCore

struct LicenseSection: View {
    @Bindable var pro: ProModel

    private var problem: LocalizedStringKey? {
        switch pro.activationProblem {
        case .unreadable: "That doesn't look like a Waft license key."
        case .invalid: "This license key isn't valid."
        case nil: nil
        }
    }

    var body: some View {
        if let license = pro.license {
            SettingsSection("License") {
                SettingsRow(.verbatim(license.holder), description: .verbatim(license.email)) {
                    Button("Remove License…", role: .destructive, action: confirmRemoval)
                }
            }
        } else {
            SettingsSection("License", subtitle: "Bought Waft+? Paste the key from your receipt email.") {
                SettingsRow("License key", description: problem) {
                    InputField("License key", prompt: .verbatim("WFT1…"), text: $pro.draft)
                        .frame(width: 220)

                    Button("Activate", action: pro.activateDraft)
                        .buttonStyle(PushButtonStyle(isProminent: true))
                        .fixedSize()
                        .disabled(!pro.canActivateDraft)
                }
            }
        }
    }

    private func confirmRemoval() {
        let confirmation = Confirmation(
            message: String(localized: "Remove the license from this Mac?"),
            detail: String(localized: "Waft+ features stop working here until you enter the key again."),
            action: String(localized: "Remove License"),
        )

        guard confirmation.ask() else { return }

        pro.deactivate()
    }
}
