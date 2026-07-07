import SwiftUI

struct ReadmeSectionView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject var viewModel: RepositoryReadmeViewModel
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("README"))
                .font(.headline)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            loadingView
        case .loading:
            loadingView
        case .loaded(_, let readme):
            ReadmeWebView(html: readme.html, baseURL: readme.baseURL)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary.opacity(0.7))
                }
        case .empty:
            ContentUnavailableView(
                localized("No README found"),
                systemImage: "doc.text.magnifyingglass",
                description: Text(localized("This repository does not have a README."))
            )
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        case .failed(_, let message):
            VStack(alignment: .leading, spacing: 10) {
                Label(localized("Could not load README"), systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button {
                    Task { await viewModel.retry() }
                } label: {
                    Label(localized("Retry"), systemImage: "arrow.clockwise")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
            .padding(14)
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(localized("Loading README..."))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: appSettings.language)
    }
}
