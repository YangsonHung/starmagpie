import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var repository: StarRepository?

    var body: some View {
        Group {
            if let repository {
                SessionView(repository: repository)
            } else {
                ProgressView("Starting...")
                    .task {
                        if repository == nil {
                            repository = StarRepository(modelContext: modelContext)
                        }
                    }
            }
        }
        .frame(minWidth: 1080, minHeight: 680)
    }
}

private struct SessionView: View {
    @ObservedObject var repository: StarRepository
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainView(repository: repository) {
                    repository.signOut()
                    isAuthenticated = false
                }
            } else {
                LoginView(repository: repository) {
                    isAuthenticated = true
                    Task { await repository.syncStars() }
                }
            }
        }
        .onAppear {
            isAuthenticated = repository.hasSavedToken
        }
    }
}
