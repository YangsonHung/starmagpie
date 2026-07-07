import AppKit
import SwiftData
import SwiftUI

struct RepositoryDetailView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Bindable var repo: StarredRepo
    let onUnstar: () -> Void

    @StateObject private var readmeViewModel: RepositoryReadmeViewModel
    @State private var showingUnstarConfirmation = false

    init(
        repo: StarredRepo,
        readmeProvider: any RepositoryReadmeProvider,
        onUnstar: @escaping () -> Void
    ) {
        self.repo = repo
        self.onUnstar = onUnstar
        _readmeViewModel = StateObject(wrappedValue: RepositoryReadmeViewModel(provider: readmeProvider))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    repositoryOverview
                    ReadmeSectionView(
                        viewModel: readmeViewModel,
                        height: readmeHeight(for: geometry.size)
                    )
                    notesEditor
                    actions
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(repo.name)
        .onAppear {
            repo.lastViewedAt = Date()
            try? modelContext.save()
        }
        .task(id: repo.id) {
            await readmeViewModel.load(repo: repo)
        }
        .alert(localized("Unstar Repository"), isPresented: $showingUnstarConfirmation) {
            Button(localized("Cancel"), role: .cancel) {}
            Button(localized("Confirm Unstar"), role: .destructive) {
                onUnstar()
            }
        } message: {
            Text(AppLocalizer.text("This will remove %@ from your GitHub Stars.", language: language, repo.fullName))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.fullName)
                        .font(.title.bold())
                        .textSelection(.enabled)
                    Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : localized("No description"))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer()
            }

            if !repo.topics.isEmpty {
                FlowLayout(alignment: .leading, spacing: 6) {
                    ForEach(repo.topics, id: \.self) { topic in
                        Text(topic)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary.opacity(0.6), in: Capsule())
                    }
                }
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 14) {
            stat("Stars", value: repo.stars.formatted(), icon: "star")
            stat("Forks", value: repo.forks.formatted(), icon: "tuningfork")
            stat("Language", value: repo.displayLanguage(language: language), icon: "curlybraces")
        }
    }

    private var repositoryOverview: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                stats
                metadata
                Spacer(minLength: 12)
                categoryPicker
            }

            VStack(alignment: .leading, spacing: 18) {
                stats
                metadata
                categoryPicker
            }
        }
    }

    private var metadata: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text(localized("Owner")).foregroundStyle(.secondary)
                Text(repo.ownerLogin).textSelection(.enabled)
            }
            GridRow {
                Text(localized("Created")).foregroundStyle(.secondary)
                Text(formattedDate(repo.createdAt, date: .numeric, time: .omitted))
            }
            GridRow {
                Text(localized("Pushed")).foregroundStyle(.secondary)
                Text(formattedDate(repo.pushedAt ?? repo.updatedAt, date: .numeric, time: .shortened))
            }
            if let starredAt = repo.starredAt {
                GridRow {
                    Text(localized("Starred")).foregroundStyle(.secondary)
                    Text(formattedDate(starredAt, date: .numeric, time: .shortened))
                }
            }
        }
    }

    private var categoryPicker: some View {
        Picker(localized("Manual Category"), selection: categoryBinding) {
            Text(localized("Auto Category")).tag("")
            Divider()
            ForEach(CategoryRule.defaults) { category in
                Text(localized(category.name)).tag(category.id)
            }
            Divider()
            Text(localized("Force Uncategorized")).tag(CategoryRule.uncategorizedId)
        }
        .pickerStyle(.menu)
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("Notes"))
                .font(.headline)
            TextEditor(text: $repo.notes)
                .font(.body)
                .frame(minHeight: 110)
                .padding(6)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: repo.notes) {
                    try? modelContext.save()
                }
        }
    }

    private var actions: some View {
        HStack {
            Button {
                openRepository()
            } label: {
                Label(localized("Open GitHub"), systemImage: "arrow.up.right.square")
            }

            Button {
                copyURL()
            } label: {
                Label(localized("Copy Link"), systemImage: "doc.on.doc")
            }

            Spacer()

            Button(role: .destructive) {
                showingUnstarConfirmation = true
            } label: {
                Label(localized("Unstar"), systemImage: "star.slash")
            }
        }
    }

    private var categoryBinding: Binding<String> {
        Binding {
            repo.manualCategoryId ?? ""
        } set: { newValue in
            repo.manualCategoryId = newValue.isEmpty ? nil : newValue
            try? modelContext.save()
        }
    }

    private func stat(_ titleKey: String, value: String, icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Text(localized(titleKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func readmeHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.78, 640), 980)
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func formattedDate(
        _ date: Date,
        date dateStyle: Date.FormatStyle.DateStyle,
        time timeStyle: Date.FormatStyle.TimeStyle
    ) -> String {
        AppDateFormatter.text(date, date: dateStyle, time: timeStyle, language: language)
    }

    private func openRepository() {
        guard let url = URL(string: repo.htmlURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(repo.htmlURL, forType: .string)
    }
}
