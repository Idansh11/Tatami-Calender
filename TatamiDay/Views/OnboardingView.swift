import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)
            TatamiMark(size: 72)
                .padding(.bottom, 24)

            if step == 0 {
                Text("Put the day on the clock.")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("Add judo, running, walking, lifting, recovery, and anything else you train. Divide an hour into 30, 20, 15, or 10 minute blocks. Every topic has its own color.")
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 12)
            } else {
                Text("Mark it done.")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("When a session ends, Tatami Day asks you to close it. It stays on the day, and it keeps notifying you, until you mark it done.")
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 12)
            }

            Spacer()

            if step == 0 {
                Button("Continue") { step = 1 }
                    .buttonStyle(TatamiButtonStyle())
            } else {
                Button("Turn on alerts") {
                    Task {
                        _ = await NotificationScheduler.requestAuthorization()
                        store.updateSettings { $0.didFinishOnboarding = true }
                    }
                }
                .buttonStyle(TatamiButtonStyle())
                Button("Not now") {
                    store.updateSettings { $0.didFinishOnboarding = true }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.background.ignoresSafeArea())
    }
}

struct TatamiButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(Theme.tatami.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
