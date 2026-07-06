import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject var repository: StarRepository
    let onSignedOut: () -> Void

    @Query private var repositories: [StarredRepo]

    @State private var selectedCategoryId = RepositoryFilter.allCategoryId
    @State private var selectedLanguage = ""
    @State private var sortOption = SortOption.starsDesc
    @State private var searchText = ""
    @State private var selectedRepoId: Int64?
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = RepositoryArchiveDocument()

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

    var body: some View {
        NavigationSplitView {
            SidebarView(
                repositories: repositories,
                selectedCategoryId: $selectedCategoryId
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } content: {
            VStack(spacing: 0) {
                searchAndFilterBar

                Divider()

                RepositoryTableView(
                    repositories: filteredRepositories,
                    selectedRepoId: $selectedRepoId
                )
            }
            .navigationTitle("Stars")
        } detail: {
            if let selectedRepository {
                RepositoryDetailView(repo: selectedRepository) {
                    Task { await repository.unstar(selectedRepository) }
                }
            } else {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "star",
                    description: Text("Click Sync to load your GitHub Stars.")
                )
            }
        }
        .toolbar {
            ToolbarItemGroup {
                AppLanguagePicker()

                Menu {
                    Button {
                        exportRepositories()
                    } label: {
                        Label("Export Repositories", systemImage: "square.and.arrow.up")
                    }
                    .disabled(repositories.isEmpty)

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Repositories", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Data", systemImage: "externaldrive")
                }

                Button {
                    Task { await repository.syncStars() }
                } label: {
                    Label(repository.isSyncing ? AppLocalizer.text("Syncing") : AppLocalizer.text("Sync"), systemImage: "arrow.clockwise")
                }
                .disabled(repository.isSyncing)

                if repository.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                }

                Button(role: .destructive) {
                    onSignedOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
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

    private var searchAndFilterBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search name, description, topics, or notes", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

            Picker("Language", selection: $selectedLanguage) {
                Text("All Languages").tag("")
                ForEach(languages, id: \.self) { language in
                    Text(language).tag(language)
                }
            }
            .frame(width: 150)

            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .frame(width: 130)

            Text("\(filteredRepositories.count) / \(repositories.count)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(12)
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

private struct SidebarView: View {
    let repositories: [StarredRepo]
    @Binding var selectedCategoryId: String

    var body: some View {
        List(selection: $selectedCategoryId) {
            Label("All", systemImage: "tray.full")
                .badge(repositories.count)
                .tag(RepositoryFilter.allCategoryId)

            Section("Categories") {
                ForEach(CategoryRule.defaults) { category in
                    Label(AppLocalizer.text(category.name), systemImage: category.symbolName)
                        .badge(count(categoryId: category.id))
                        .tag(category.id)
                }
            }

            Section {
                Label("Uncategorized", systemImage: "questionmark.folder")
                    .badge(count(categoryId: CategoryRule.uncategorizedId))
                    .tag(CategoryRule.uncategorizedId)
            }
        }
        .navigationTitle("Categories")
    }

    private func count(categoryId: String) -> Int {
        repositories.filter {
            CategoryResolver.matches(repo: $0, selectedCategoryId: categoryId)
        }.count
    }
}

private struct RepositoryTableView: View {
    let repositories: [StarredRepo]
    @Binding var selectedRepoId: Int64?

    var body: some View {
        Table(repositories, selection: $selectedRepoId) {
            TableColumn("Repository") { repo in
                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.fullName)
                        .font(.headline)
                    Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : AppLocalizer.text("No description"))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
            .width(min: 260, ideal: 360)

            TableColumn("Language") { repo in
                Text(repo.languageDisplay)
            }
            .width(90)

            TableColumn("Stars") { repo in
                Text(repo.stars.formatted())
                    .monospacedDigit()
            }
            .width(80)

            TableColumn("Forks") { repo in
                Text(repo.forks.formatted())
                    .monospacedDigit()
            }
            .width(80)

            TableColumn("Category") { repo in
                Text(repo.categoryDisplayName)
            }
            .width(120)

            TableColumn("Updated") { repo in
                Text((repo.pushedAt ?? repo.updatedAt).formatted(date: .numeric, time: .omitted))
            }
            .width(110)
        }
    }
}
