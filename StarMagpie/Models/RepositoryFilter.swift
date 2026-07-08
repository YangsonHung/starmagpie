import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case stars
    case starred
    case updated
    case name

    var id: String { rawValue }

    var title: String {
        title(language: nil)
    }

    func title(language: AppLanguage?) -> String {
        switch self {
        case .stars: return localized("Stars", language: language)
        case .starred: return localized("Starred Date", language: language)
        case .updated: return localized("Updated Date", language: language)
        case .name: return localized("Name", language: language)
        }
    }

    func summaryTitle(language: AppLanguage?) -> String {
        switch self {
        case .stars: return localized("Stars", language: language)
        case .starred: return localized("Starred", language: language)
        case .updated: return localized("Updated", language: language)
        case .name: return localized("Name", language: language)
        }
    }

    var symbolName: String {
        switch self {
        case .stars:
            "star"
        case .starred:
            "calendar.badge.plus"
        case .updated:
            "clock.arrow.circlepath"
        case .name:
            "textformat"
        }
    }

    private func localized(_ key: String, language: AppLanguage?) -> String {
        if let language {
            return AppLocalizer.text(key, language: language)
        }
        return AppLocalizer.text(key)
    }
}

enum SortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .ascending:
            "Ascending"
        case .descending:
            "Descending"
        }
    }

    var symbolName: String {
        switch self {
        case .ascending:
            "arrow.up"
        case .descending:
            "arrow.down"
        }
    }

    var toggled: Self {
        switch self {
        case .ascending:
            .descending
        case .descending:
            .ascending
        }
    }

    func title(language: AppLanguage?) -> String {
        if let language {
            return AppLocalizer.text(titleKey, language: language)
        }
        return AppLocalizer.text(titleKey)
    }

    func title(for option: SortOption, language: AppLanguage?) -> String {
        let key: String
        switch (option, self) {
        case (.stars, .ascending):
            key = "Low to High"
        case (.stars, .descending):
            key = "High to Low"
        case (.starred, .ascending), (.updated, .ascending):
            key = "Oldest First"
        case (.starred, .descending), (.updated, .descending):
            key = "Newest First"
        case (.name, .ascending):
            key = "A to Z"
        case (.name, .descending):
            key = "Z to A"
        }

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
        sortOption: SortOption,
        sortDirection: SortDirection
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
            case .stars:
                if lhs.stars != rhs.stars {
                    return sortDirection == .ascending ? lhs.stars < rhs.stars : lhs.stars > rhs.stars
                }
            case .starred:
                if let result = compareOptionalDates(lhs.starredAt, rhs.starredAt, direction: sortDirection) {
                    return result
                }
            case .updated:
                if let result = compareDates(lhs.pushedAt ?? lhs.updatedAt, rhs.pushedAt ?? rhs.updatedAt, direction: sortDirection) {
                    return result
                }
            case .name:
                if let result = compareNames(lhs.fullName, rhs.fullName, direction: sortDirection) {
                    return result
                }
            }
            if let result = compareNames(lhs.fullName, rhs.fullName, direction: .ascending) {
                return result
            }
            return lhs.id < rhs.id
        }
    }

    private static func compareOptionalDates(_ lhs: Date?, _ rhs: Date?, direction: SortDirection) -> Bool? {
        switch (lhs, rhs) {
        case (nil, nil):
            return nil
        case (nil, _):
            return false
        case (_, nil):
            return true
        case let (lhs?, rhs?):
            return compareDates(lhs, rhs, direction: direction)
        }
    }

    private static func compareDates(_ lhs: Date, _ rhs: Date, direction: SortDirection) -> Bool? {
        guard lhs != rhs else { return nil }
        return direction == .ascending ? lhs < rhs : lhs > rhs
    }

    private static func compareNames(_ lhs: String, _ rhs: String, direction: SortDirection) -> Bool? {
        let comparison = lhs.localizedCaseInsensitiveCompare(rhs)
        guard comparison != .orderedSame else { return nil }
        return direction == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
    }
}
