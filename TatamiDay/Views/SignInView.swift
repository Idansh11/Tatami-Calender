import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPrivacy = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var creating = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()
            LinearGradient(
                colors: [Theme.tatami.opacity(colorScheme == .dark ? 0.55 : 0.35), Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)
            .overlay { Weave() }
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 0) {
                TatamiMark(size: 84)
                    .padding(.top, 28)
                    .padding(.leading, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("TATAMI DAY")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(Theme.tatami)
                    Text("The private training day.")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Every hour on the clock. Judo, running, lifting, recovery. Color the work, then mark it done.")
                        .font(.body)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 14) {
                    if case .denied(let reason) = store.phase {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.ember.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        store.handle(result: result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .accessibilityHint("Signs in with the Apple ID this private app is registered to")

                    Text("Each Apple ID has its own calendar. Email and password use the same calendar when the email matches.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.ink)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.ink)

                    if creating {
                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.ink)
                    }

                    Button(creating ? "Create account" : "Sign in") {
                        if creating {
                            store.createAccount(email: email, password: password, confirm: confirmPassword)
                        } else {
                            store.signInWithEmail(email, password: password)
                        }
                    }
                    .buttonStyle(TatamiButtonStyle())
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || (creating && confirmPassword.isEmpty))

                    Button(creating ? "Already have an account? Sign in" : "Create an account") {
                        creating.toggle()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                    Button("Privacy policy") { showPrivacy = true }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyView(showsDone: true)
            }
            .presentationBackground(Theme.background)
        }
    }
}
