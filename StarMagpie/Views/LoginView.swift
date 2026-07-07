import AppKit
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject var repository: StarRepository
    let onSignedIn: () -> Void

    @State private var token = ""
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                AppLanguagePicker()
            }

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)

                Text("StarMagpie")
                    .font(.largeTitle.bold())

                Text(localized("Sync and manage your GitHub Stars with a Personal Access Token."))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(localized("GitHub Token"))
                    .font(.headline)

                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { signIn() }

                if let errorMessage = repository.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                Button {
                    signIn()
                } label: {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isSigningIn ? localized("Connecting...") : localized("Connect GitHub"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSigningIn)
            }
            .frame(width: 420)

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("Token Permissions"))
                    .font(.headline)
                Text(localized("StarMagpie needs permission to read your Stars. Unstarring requires write access to starred repositories. Fine-grained tokens can grant the matching account resource permission."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button(localized("Open GitHub Token Settings")) {
                    NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens")!)
                }
                .buttonStyle(.link)
            }
            .frame(width: 420, alignment: .leading)

            Spacer()
        }
        .padding(40)
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private func signIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        Task {
            let success = await repository.signIn(token: token)
            await MainActor.run {
                isSigningIn = false
                if success {
                    token = ""
                    onSignedIn()
                }
            }
        }
    }
}
