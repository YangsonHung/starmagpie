import AppKit
import SwiftData
import SwiftUI

struct RepositoryDetailView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var repo: StarredRepo
    let onUnstar: () -> Void

    @StateObject private var readmeViewModel: RepositoryReadmeViewModel
    @State private var showingUnstarConfirmation = false
    @State private var isNotesExpanded = false

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
            VStack(spacing: 0) {
                sheetHeader

                Divider()

                HStack(spacing: 0) {
                    detailSidebar
                        .frame(width: 320)

                    Divider()

                    ReadmeSectionView(
                        viewModel: readmeViewModel,
                        height: readmeHeight(for: geometry.size)
                    )
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(minWidth: 980, idealWidth: 1120, minHeight: 680, idealHeight: 760)
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
                dismiss()
            }
        } message: {
            Text(AppLocalizer.text("This will remove %@ from your GitHub Stars.", language: language, repo.fullName))
        }
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            RepositoryAvatarView(urlString: repo.ownerAvatarURL, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.fullName)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .textSelection(.enabled)
                Text(localized("README"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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

            Button(role: .destructive) {
                showingUnstarConfirmation = true
            } label: {
                Label(localized("Unstar"), systemImage: "star.slash")
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            .help(localized("Close"))
        }
        .controlSize(.small)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var detailSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sidebarSummary
                stats
                metadataSection
                categorySection
                notesEditor
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.quaternary.opacity(0.12))
    }

    private var sidebarSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : localized("No description"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if !repo.topics.isEmpty {
                FlowLayout(alignment: .leading, spacing: 6) {
                    ForEach(repo.topics.prefix(8), id: \.self) { topic in
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
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 116), spacing: 8),
                GridItem(.flexible(minimum: 116), spacing: 8)
            ],
            alignment: .leading,
            spacing: 8
        ) {
            stat("Stars", value: repo.stars.formatted(), icon: "star")
            stat("Forks", value: repo.forks.formatted(), icon: "tuningfork")
            stat("Language", value: repo.displayLanguage(language: language), icon: "curlybraces")
        }
    }

    private var repositoryOverview: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                stats
                metadata
                Spacer(minLength: 12)
                categoryPicker
            }

            VStack(alignment: .leading, spacing: 12) {
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

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized("Details"))
                .font(.headline)
            metadata
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("Manual Category"))
                .font(.headline)
            categoryPicker
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
        .controlSize(.small)
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(localized("Notes"))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isNotesExpanded.toggle()
                    }
                } label: {
                    Label(
                        localized(isNotesExpanded ? "Collapse Notes" : "Expand Notes"),
                        systemImage: isNotesExpanded ? "chevron.up" : "chevron.down"
                    )
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $repo.notes)
                    .font(.body)
                    .frame(height: isNotesExpanded ? 136 : 54)
                    .padding(6)
                    .scrollContentBackground(.hidden)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                    .onChange(of: repo.notes) {
                        try? modelContext.save()
                    }

                if repo.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(localized("Add a note about why this repository matters, how to use it, or what to revisit."))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
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
        .controlSize(.small)
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
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(localized(titleKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func readmeHeight(for size: CGSize) -> CGFloat {
        max(size.height - 156, 460)
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
