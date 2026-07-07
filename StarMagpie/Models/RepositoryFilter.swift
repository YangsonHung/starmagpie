import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case starsDesc
    case starredDesc
    case updatedDesc
    case nameAsc

    var id: String { rawValue }

    var title: String {
        title(language: nil)
    }

    func title(language: AppLanguage?) -> String {
        switch self {
        case .starsDesc: return localized("Stars", language: language)
        case .starredDesc: return localized("Starred Date", language: language)
        case .updatedDesc: return localized("Updated Date", language: language)
        case .nameAsc: return localized("Name", language: language)
        }
    }

    private func localized(_ key: String, language: AppLanguage?) -> String {
        if let language {
            return AppLocalizer.text(key, language: language)
        }
        return AppLocalizer.text(key)
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
