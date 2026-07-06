import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case starsDesc
    case starredDesc
    case updatedDesc
    case nameAsc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starsDesc: return AppLocalizer.text("Stars")
        case .starredDesc: return AppLocalizer.text("Starred Date")
        case .updatedDesc: return AppLocalizer.text("Updated Date")
        case .nameAsc: return AppLocalizer.text("Name")
        }
    }
}

enum RepositoryFilter {
    static let allCategoryId = "__all__"

    static func filtered(
        _ repositories: [StarredRepo],
        searchText: String,
        selectedCategoryId: String?,
        selectedLanguage: String?,
        sortOption: SortOption
    ) -> [StarredRepo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let language = selectedLanguage?.isEmpty == false ? selectedLanguage : nil

        let filtered = repositories.filter { repo in
            if !CategoryResolver.matches(repo: repo, selectedCategoryId: selectedCategoryId) {
                return false
            }

            if let language, language != repo.language {
                return false
            }

            if query.isEmpty {
                return true
            }

            let searchableText = [
                repo.name,
                repo.fullName,
                repo.descriptionText ?? "",
                repo.language ?? "",
                repo.topics.joined(separator: " "),
                repo.notes
            ]
            .joined(separator: " ")
            .lowercased()

            return query
                .split(whereSeparator: { $0.isWhitespace })
                .allSatisfy { searchableText.contains($0) }
        }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .starsDesc:
                if lhs.stars == rhs.stars { return lhs.fullName < rhs.fullName }
                return lhs.stars > rhs.stars
            case .starredDesc:
                return (lhs.starredAt ?? .distantPast) > (rhs.starredAt ?? .distantPast)
            case .updatedDesc:
                return (lhs.pushedAt ?? lhs.updatedAt) > (rhs.pushedAt ?? rhs.updatedAt)
            case .nameAsc:
                return lhs.fullName.localizedCaseInsensitiveCompare(rhs.fullName) == .orderedAscending
            }
        }
    }
}
