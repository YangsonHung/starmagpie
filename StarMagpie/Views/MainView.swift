import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject var repository: StarRepository
    let onSignedOut: () -> Void
    private let readmeProvider: any RepositoryReadmeProvider

    @Query private var repositories: [StarredRepo]

    @State private var selectedCategoryId = RepositoryFilter.allCategoryId
    @State private var selectedLanguage = ""
    @State private var sortOption = SortOption.starsDesc
    @State private var searchText = ""
    @State private var browserLayout = RepositoryBrowserLayout.list
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = RepositoryArchiveDocument()

    init(
        repository: StarRepository,
        readmeProvider: any RepositoryReadmeProvider = GitHubRepositoryReadmeProvider(),
        onSignedOut: @escaping () -> Void
    ) {
        self.repository = repository
        self.readmeProvider = readmeProvider
        self.onSignedOut = onSignedOut
    }

    private var languages: [String] {
        Array(Set(repositories.compactMap(\.language))).sorted()
    }

    private var filteredRepositories: [StarredRepo] {
        RepositoryFilter.filtered(
            repositories,
            searchText: searchText,
            selectedCategoryId: selectedCategoryId,
            selectedLanguage: selectedLanguage,
            sortOption: sortOption
        )
    }

    private var categoryCounts: [String: Int] {
        var counts = [RepositoryFilter.allCategoryId: repositories.count]
        for repo in repositories {
            let categoryId = CategoryResolver.resolvedCategoryId(for: repo) ?? CategoryRule.uncategorizedId
            counts[categoryId, default: 0] += 1
        }
        return counts
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedCategoryId: $selectedCategoryId,
                categoryCounts: categoryCounts
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            RepositoryBrowserView(
                repositories: repositories,
                filteredRepositories: filteredRepositories,
                languages: languages,
                selectedLanguage: $selectedLanguage,
                sortOption: $sortOption,
                searchText: $searchText,
                layoutMode: $browserLayout,
                readmeProvider: readmeProvider
            ) { repo in
                Task { await repository.unstar(repo) }
            }
            .localizedNavigationTitle("Stars")
            .navigationSplitViewColumnWidth(min: 720, ideal: 1120)
        }
        .toolbar {
            ToolbarItemGroup {
                AppLanguagePicker()

                Menu {
                    Button {
                        exportRepositories()
                    } label: {
                        LocalizedLabel(key: "Export Repositories", systemImage: "square.and.arrow.up")
                    }
                    .disabled(repositories.isEmpty)

                    Button {
                        isImporting = true
                    } label: {
                        LocalizedLabel(key: "Import Repositories", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    LocalizedLabel(key: "Data", systemImage: "externaldrive")
                }

                Button {
                    Task { await repository.syncStars() }
                } label: {
                    LocalizedLabel(key: repository.isSyncing ? "Syncing" : "Sync", systemImage: "arrow.clockwise")
                }
                .disabled(repository.isSyncing)

                if repository.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                }

                Button(role: .destructive) {
                    onSignedOut()
                } label: {
                    LocalizedLabel(key: "Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: importRepositories
        )
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "StarMagpie-Repositories",
            onCompletion: handleExportCompletion
        )
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let errorMessage = repository.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.red.gradient, in: Capsule())
                }

                if let statusMessage = repository.statusMessage {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.green.gradient, in: Capsule())
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func exportRepositories() {
        do {
            exportDocument = RepositoryArchiveDocument(data: try repository.exportArchiveData())
            isExporting = true
        } catch {
            repository.report(error)
        }
    }

    private func importRepositories(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            try repository.importArchiveData(data)
        } catch {
            repository.report(error)
        }
    }

    private func handleExportCompletion(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            repository.report(error)
        }
    }
}

private enum RepositoryBrowserLayout: String, CaseIterable, Identifiable {
    case list
    case cards

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .list:
            "List"
        case .cards:
            "Cards"
        }
    }

    var symbolName: String {
        switch self {
        case .list:
            "list.bullet"
        case .cards:
            "square.grid.2x2"
        }
    }
}

private struct RepositoryBrowserView: View {
    @EnvironmentObject private var appSettings: AppSettings
    let repositories: [StarredRepo]
    let filteredRepositories: [StarredRepo]
    let languages: [String]
    @Binding var selectedLanguage: String
    @Binding var sortOption: SortOption
    @Binding var searchText: String
    @Binding var layoutMode: RepositoryBrowserLayout
    let readmeProvider: any RepositoryReadmeProvider
    let onUnstar: (StarredRepo) -> Void

    @State private var selectedRepoId: Int64?
    @State private var presentedRepoId: Int64?
    @State private var unstarCandidateId: Int64?

    var body: some View {
        VStack(spacing: 0) {
            SearchAndFilterBar(
                languages: languages,
                selectedLanguage: $selectedLanguage,
                sortOption: $sortOption,
                searchText: $searchText,
                layoutMode: $layoutMode,
                filteredCount: filteredRepositories.count,
                totalCount: repositories.count
            )

            Divider()

            if filteredRepositories.isEmpty {
                EmptyRepositoryListView(hasRepositories: !repositories.isEmpty)
            } else {
                content
            }
        }
        .sheet(isPresented: detailSheetBinding, onDismiss: {
            selectedRepoId = nil
        }) {
            if let presentedRepository {
                RepositoryDetailView(
                    repo: presentedRepository,
                    readmeProvider: readmeProvider
                ) {
                    onUnstar(presentedRepository)
                    presentedRepoId = nil
                }
            }
        }
        .alert(localized("Unstar Repository"), isPresented: unstarAlertBinding) {
            Button(localized("Cancel"), role: .cancel) {}
            Button(localized("Confirm Unstar"), role: .destructive) {
                if let unstarCandidate {
                    onUnstar(unstarCandidate)
                    if presentedRepoId == unstarCandidate.id {
                        presentedRepoId = nil
                    }
                }
                unstarCandidateId = nil
            }
        } message: {
            if let unstarCandidate {
                Text(AppLocalizer.text("This will remove %@ from your GitHub Stars.", language: language, unstarCandidate.fullName))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch layoutMode {
        case .list:
            RepositoryTableView(
                repositories: filteredRepositories,
                selectedRepoId: $selectedRepoId
            )
            .onChange(of: selectedRepoId) {
                if let selectedRepoId {
                    presentedRepoId = selectedRepoId
                }
            }
        case .cards:
            RepositoryCardGridView(
                repositories: filteredRepositories,
                onOpen: openDetails,
                onOpenGitHub: openRepository,
                onCopyLink: copyURL,
                onUnstar: { repo in
                    unstarCandidateId = repo.id
                }
            )
        }
    }

    private var detailSheetBinding: Binding<Bool> {
        Binding {
            presentedRepoId != nil
        } set: { isPresented in
            if !isPresented {
                presentedRepoId = nil
            }
        }
    }

    private var unstarAlertBinding: Binding<Bool> {
        Binding {
            unstarCandidateId != nil
        } set: { isPresented in
            if !isPresented {
                unstarCandidateId = nil
            }
        }
    }

    private var presentedRepository: StarredRepo? {
        guard let presentedRepoId else { return nil }
        return repositories.first { $0.id == presentedRepoId }
    }

    private var unstarCandidate: StarredRepo? {
        guard let unstarCandidateId else { return nil }
        return repositories.first { $0.id == unstarCandidateId }
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private func openDetails(_ repo: StarredRepo) {
        selectedRepoId = repo.id
        presentedRepoId = repo.id
    }

    private func openRepository(_ repo: StarredRepo) {
        guard let url = URL(string: repo.htmlURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyURL(_ repo: StarredRepo) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(repo.htmlURL, forType: .string)
    }
}

private struct SearchAndFilterBar: View {
    @EnvironmentObject private var appSettings: AppSettings
    let languages: [String]
    @Binding var selectedLanguage: String
    @Binding var sortOption: SortOption
    @Binding var searchText: String
    @Binding var layoutMode: RepositoryBrowserLayout
    let filteredCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(localized("Search name, description, topics, or notes"), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

            Picker(localized("Language"), selection: $selectedLanguage) {
                Text(localized("All Languages")).tag("")
                ForEach(languages, id: \.self) { repositoryLanguage in
                    Text(repositoryLanguage).tag(repositoryLanguage)
                }
            }
            .frame(width: 142)

            Picker(localized("Sort"), selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title(language: language)).tag(option)
                }
            }
            .frame(width: 122)

            Text("\(filteredCount) / \(totalCount)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Spacer(minLength: 8)

            Picker(localized("View"), selection: $layoutMode) {
                ForEach(RepositoryBrowserLayout.allCases) { layout in
                    Label(localized(layout.titleKey), systemImage: layout.symbolName)
                        .tag(layout)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 132)
        }
        .controlSize(.small)
        .padding(8)
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Binding var selectedCategoryId: String
    let categoryCounts: [String: Int]

    var body: some View {
        List(selection: $selectedCategoryId) {
            Label(localized("All"), systemImage: "tray.full")
                .badge(count(categoryId: RepositoryFilter.allCategoryId))
                .tag(RepositoryFilter.allCategoryId)

            Section(localized("Categories")) {
                ForEach(CategoryRule.defaults) { category in
                    Label(localized(category.name), systemImage: category.symbolName)
                        .badge(count(categoryId: category.id))
                        .tag(category.id)
                }
            }

            Section {
                Label(localized("Uncategorized"), systemImage: "questionmark.folder")
                    .badge(count(categoryId: CategoryRule.uncategorizedId))
                    .tag(CategoryRule.uncategorizedId)
            }
        }
        .localizedNavigationTitle("Categories")
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func count(categoryId: String) -> Int {
        categoryCounts[categoryId, default: 0]
    }
}

private struct RepositoryTableView: View {
    @EnvironmentObject private var appSettings: AppSettings
    let repositories: [StarredRepo]
    @Binding var selectedRepoId: Int64?

    var body: some View {
        Table(repositories, selection: $selectedRepoId) {
            TableColumn(localized("Repository")) { repo in
                VStack(alignment: .leading, spacing: 1) {
                    Text(repo.fullName)
                        .font(.headline)
                    Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : localized("No description"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 3)
            }
            .width(min: 280, ideal: 380)

            TableColumn(localized("Language")) { repo in
                Text(repo.displayLanguage(language: language))
            }
            .width(96)

            TableColumn(localized("Stars")) { repo in
                Text(repo.stars.formatted())
                    .monospacedDigit()
            }
            .width(78)

            TableColumn(localized("Forks")) { repo in
                Text(repo.forks.formatted())
                    .monospacedDigit()
            }
            .width(78)

            TableColumn(localized("Category")) { repo in
                Text(repo.displayCategoryName(language: language))
            }
            .width(112)

            TableColumn(localized("Updated")) { repo in
                Text(formattedDate(repo.pushedAt ?? repo.updatedAt, date: .numeric, time: .omitted))
            }
            .width(104)
        }
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private func formattedDate(
        _ date: Date,
        date dateStyle: Date.FormatStyle.DateStyle,
        time timeStyle: Date.FormatStyle.TimeStyle
    ) -> String {
        AppDateFormatter.text(date, date: dateStyle, time: timeStyle, language: language)
    }
}

private struct RepositoryCardGridView: View {
    let repositories: [StarredRepo]
    let onOpen: (StarredRepo) -> Void
    let onOpenGitHub: (StarredRepo) -> Void
    let onCopyLink: (StarredRepo) -> Void
    let onUnstar: (StarredRepo) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 16, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(repositories) { repo in
                    RepositoryCardView(
                        repo: repo,
                        onOpen: onOpen,
                        onOpenGitHub: onOpenGitHub,
                        onCopyLink: onCopyLink,
                        onUnstar: onUnstar
                    )
                }
            }
            .padding(18)
        }
    }
}

private struct RepositoryCardView: View {
    @EnvironmentObject private var appSettings: AppSettings
    let repo: StarredRepo
    let onOpen: (StarredRepo) -> Void
    let onOpenGitHub: (StarredRepo) -> Void
    let onCopyLink: (StarredRepo) -> Void
    let onUnstar: (StarredRepo) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader

            quickActions

            VStack(alignment: .leading, spacing: 14) {
                Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : localized("No description"))
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)

                topicChips

                Spacer(minLength: 0)

                Divider()

                cardFooter
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 218, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.secondary.opacity(0.45) : Color.secondary.opacity(0.16))
        }
        .onHover { isHovering = $0 }
        .onTapGesture {
            onOpen(repo)
        }
        .help(localized("Open Details"))
    }

    private var cardHeader: some View {
        HStack(spacing: 10) {
            RepositoryAvatarView(urlString: repo.ownerAvatarURL, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(repo.ownerLogin)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            Button {
                onOpen(repo)
            } label: {
                Image(systemName: "book")
                    .frame(width: 26, height: 26)
            }
            .help(localized("Open Details"))

            Button {
                onCopyLink(repo)
            } label: {
                Image(systemName: "doc.on.doc")
                    .frame(width: 26, height: 26)
            }
            .help(localized("Copy Link"))

            Button {
                onOpenGitHub(repo)
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .frame(width: 26, height: 26)
            }
            .help(localized("Open GitHub"))

            Button(role: .destructive) {
                onUnstar(repo)
            } label: {
                Image(systemName: "star.slash")
                    .frame(width: 26, height: 26)
            }
            .help(localized("Unstar"))

            Spacer()
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
    }

    @ViewBuilder
    private var topicChips: some View {
        let chips = Array(repo.topics.prefix(3))
        if chips.isEmpty {
            Text(repo.displayCategoryName(language: language))
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        } else {
            HStack(spacing: 6) {
                ForEach(chips, id: \.self) { topic in
                    Text(topic)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var cardFooter: some View {
        HStack(spacing: 14) {
            Label(repo.stars.formatted(), systemImage: "star")
                .monospacedDigit()

            Label(formattedDate(repo.pushedAt ?? repo.updatedAt, date: .numeric, time: .omitted), systemImage: "calendar")
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var cardBackground: Color {
        isHovering ? Color(nsColor: .controlAccentColor).opacity(0.08) : Color(nsColor: .controlBackgroundColor)
    }

    private var language: AppLanguage {
        appSettings.language
    }

    private func localized(_ key: String) -> String {
        AppLocalizer.text(key, language: language)
    }

    private func formattedDate(
        _ date: Date,
        date dateStyle: Date.FormatStyle.DateStyle,
        time timeStyle: Date.FormatStyle.TimeStyle
    ) -> String {
        AppDateFormatter.text(date, date: dateStyle, time: timeStyle, language: language)
    }
}

struct RepositoryAvatarView: View {
    let urlString: String
    let size: CGFloat

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fallback: some View {
        Image(systemName: "shippingbox")
            .font(.system(size: size * 0.48))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyRepositoryListView: View {
    @EnvironmentObject private var appSettings: AppSettings
    let hasRepositories: Bool

    var body: some View {
        ContentUnavailableView(
            AppLocalizer.text(hasRepositories ? "No Matching Repositories" : "No Repositories", language: language),
            systemImage: "star",
            description: Text(AppLocalizer.text(
                hasRepositories ? "Try another search, language, or category." : "Click Sync to load your GitHub Stars.",
                language: language
            ))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var language: AppLanguage {
        appSettings.language
    }
}
