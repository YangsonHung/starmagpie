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
    @State private var selectedRepoId: Int64?
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

    private var selectedRepository: StarredRepo? {
        if let selectedRepoId,
           let selected = filteredRepositories.first(where: { $0.id == selectedRepoId }) {
            return selected
        }
        return filteredRepositories.first
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
        } content: {
            VStack(spacing: 0) {
                SearchAndFilterBar(
                    languages: languages,
                    selectedLanguage: $selectedLanguage,
                    sortOption: $sortOption,
                    searchText: $searchText,
                    filteredCount: filteredRepositories.count,
                    totalCount: repositories.count
                )

                Divider()

                RepositoryTableView(
                    repositories: filteredRepositories,
                    selectedRepoId: $selectedRepoId
                )
            }
            .localizedNavigationTitle("Stars")
            .navigationSplitViewColumnWidth(min: 360, ideal: 460, max: 560)
        } detail: {
            if let selectedRepository {
                RepositoryDetailView(
                    repo: selectedRepository,
                    readmeProvider: readmeProvider
                ) {
                    Task { await repository.unstar(selectedRepository) }
                }
            } else {
                EmptyRepositoryDetailView()
            }
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
            selectedRepoId = nil
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

private struct SearchAndFilterBar: View {
    @EnvironmentObject private var appSettings: AppSettings
    let languages: [String]
    @Binding var selectedLanguage: String
    @Binding var sortOption: SortOption
    @Binding var searchText: String
    let filteredCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(localized("Search name, description, topics, or notes"), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

            Picker(localized("Language"), selection: $selectedLanguage) {
                Text(localized("All Languages")).tag("")
                ForEach(languages, id: \.self) { repositoryLanguage in
                    Text(repositoryLanguage).tag(repositoryLanguage)
                }
            }
            .frame(width: 150)

            Picker(localized("Sort"), selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title(language: language)).tag(option)
                }
            }
            .frame(width: 130)

            Text("\(filteredCount) / \(totalCount)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(12)
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.fullName)
                        .font(.headline)
                    Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : localized("No description"))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
            .width(min: 260, ideal: 360)

            TableColumn(localized("Language")) { repo in
                Text(repo.displayLanguage(language: language))
            }
            .width(90)

            TableColumn(localized("Stars")) { repo in
                Text(repo.stars.formatted())
                    .monospacedDigit()
            }
            .width(80)

            TableColumn(localized("Forks")) { repo in
                Text(repo.forks.formatted())
                    .monospacedDigit()
            }
            .width(80)

            TableColumn(localized("Category")) { repo in
                Text(repo.displayCategoryName(language: language))
            }
            .width(120)

            TableColumn(localized("Updated")) { repo in
                Text(formattedDate(repo.pushedAt ?? repo.updatedAt, date: .numeric, time: .omitted))
            }
            .width(110)
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

private struct EmptyRepositoryDetailView: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        ContentUnavailableView(
            AppLocalizer.text("No Repositories", language: language),
            systemImage: "star",
            description: Text(AppLocalizer.text("Click Sync to load your GitHub Stars.", language: language))
        )
    }

    private var language: AppLanguage {
        appSettings.language
    }
}
