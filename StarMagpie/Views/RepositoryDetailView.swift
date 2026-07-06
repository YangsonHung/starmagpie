import AppKit
import SwiftData
import SwiftUI

struct RepositoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var repo: StarredRepo
    let onUnstar: () -> Void

    @State private var showingUnstarConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                stats
                metadata
                categoryPicker
                notesEditor
                actions
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(repo.name)
        .onAppear {
            repo.lastViewedAt = Date()
            try? modelContext.save()
        }
        .alert("Unstar Repository", isPresented: $showingUnstarConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Unstar", role: .destructive) {
                onUnstar()
            }
        } message: {
            Text("This will remove \(repo.fullName) from your GitHub Stars.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.fullName)
                        .font(.title.bold())
                        .textSelection(.enabled)
                    Text(repo.descriptionText?.isEmpty == false ? repo.descriptionText! : AppLocalizer.text("No description"))
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
            stat(AppLocalizer.text("Language"), value: repo.languageDisplay, icon: "curlybraces")
        }
    }

    private var metadata: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Owner").foregroundStyle(.secondary)
                Text(repo.ownerLogin).textSelection(.enabled)
            }
            GridRow {
                Text("Created").foregroundStyle(.secondary)
                Text(repo.createdAt.formatted(date: .numeric, time: .omitted))
            }
            GridRow {
                Text("Pushed").foregroundStyle(.secondary)
                Text((repo.pushedAt ?? repo.updatedAt).formatted(date: .numeric, time: .shortened))
            }
            if let starredAt = repo.starredAt {
                GridRow {
                    Text("Starred").foregroundStyle(.secondary)
                    Text(starredAt.formatted(date: .numeric, time: .shortened))
                }
            }
        }
    }

    private var categoryPicker: some View {
        Picker("Manual Category", selection: categoryBinding) {
            Text("Auto Category").tag("")
            Divider()
            ForEach(CategoryRule.defaults) { category in
                Text(AppLocalizer.text(category.name)).tag(category.id)
            }
            Divider()
            Text("Force Uncategorized").tag(CategoryRule.uncategorizedId)
        }
        .pickerStyle(.menu)
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextEditor(text: $repo.notes)
                .font(.body)
                .frame(minHeight: 150)
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
                Label("Open GitHub", systemImage: "arrow.up.right.square")
            }

            Button {
                copyURL()
            } label: {
                Label("Copy Link", systemImage: "doc.on.doc")
            }

            Spacer()

            Button(role: .destructive) {
                showingUnstarConfirmation = true
            } label: {
                Label("Unstar", systemImage: "star.slash")
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

    private func stat(_ title: String, value: String, icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Text(title)
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

    private func openRepository() {
        guard let url = URL(string: repo.htmlURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(repo.htmlURL, forType: .string)
    }
}
