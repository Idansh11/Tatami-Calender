import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    var showsDone = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Last updated 17 November 2026")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)

                policyBlock(
                    "Who",
                    "Tatami Day is a private training calendar made for one athlete. The developer is Idan Shoshany, idan.shoshany.2011@gmail.com."
                )
                policyBlock(
                    "What stays on this iPhone",
                    "Sign in with Apple can share a stable user id, your email address, and your name. Tatami Day stores those in the iPhone Keychain. Training sessions, topics, notes, places, and settings are stored in the app’s private sandbox. Notification reminders are stored by iOS on this device."
                )
                policyBlock(
                    "What leaves this iPhone",
                    "Sign in with Apple is provided by Apple. Your device talks to Apple to authenticate. Tatami Day has no server, no analytics, no advertising SDK, and no tracking. A backup file is created only when you tap Export, and it goes only where you send it."
                )
                policyBlock(
                    "Who can open it",
                    "Anyone can sign in. Each Apple ID, and each email account, has its own calendar on this iPhone. Signing in with Apple and with the same email opens the same calendar."
                )
                policyBlock(
                    "Notifications",
                    "If you allow alerts, the app schedules local reminders before a session and again when a session needs to be marked done. You can turn alerts off in iOS Settings."
                )
                policyBlock(
                    "Delete",
                    "Athlete → Delete account removes the Keychain identity, sessions, topics you created, and pending notifications from this iPhone. You can also revoke Tatami Day under Settings → Apple ID → Sign in with Apple."
                )
                policyBlock(
                    "Children",
                    "Tatami Day is not directed at children under 13."
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDone {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func policyBlock(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(body)
                .font(.body)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
