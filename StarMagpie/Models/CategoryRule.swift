import Foundation

struct CategoryRule: Identifiable, Hashable {
    let id: String
    let name: String
    let symbolName: String
    let keywords: [String]

    static let uncategorizedId = "__uncategorized__"

    static let defaults: [CategoryRule] = [
        CategoryRule(id: "web", name: "Web Apps", symbolName: "globe", keywords: ["web应用", "web", "website", "frontend", "react", "vue", "angular"]),
        CategoryRule(id: "mobile", name: "Mobile Apps", symbolName: "iphone", keywords: ["移动应用", "mobile", "android", "ios", "flutter", "react-native"]),
        CategoryRule(id: "desktop", name: "Desktop Apps", symbolName: "desktopcomputer", keywords: ["桌面应用", "desktop", "electron", "gui", "qt", "gtk"]),
        CategoryRule(id: "database", name: "Databases", symbolName: "externaldrive", keywords: ["数据库", "database", "sql", "nosql", "mongodb", "mysql", "postgresql"]),
        CategoryRule(id: "ai", name: "AI / Machine Learning", symbolName: "brain.head.profile", keywords: ["ai工具", "ai", "ml", "machine learning", "deep learning", "neural"]),
        CategoryRule(id: "devtools", name: "Developer Tools", symbolName: "hammer", keywords: ["开发工具", "tool", "cli", "build", "deploy", "debug", "test", "automation"]),
        CategoryRule(id: "security", name: "Security Tools", symbolName: "lock.shield", keywords: ["安全工具", "security", "encryption", "auth", "vulnerability"]),
        CategoryRule(id: "game", name: "Games", symbolName: "gamecontroller", keywords: ["游戏", "game", "gaming", "unity", "unreal", "godot"]),
        CategoryRule(id: "design", name: "Design Tools", symbolName: "paintpalette", keywords: ["设计工具", "design", "ui", "ux", "graphics", "image"]),
        CategoryRule(id: "productivity", name: "Productivity", symbolName: "bolt", keywords: ["效率工具", "productivity", "note", "todo", "calendar", "task"]),
        CategoryRule(id: "education", name: "Education", symbolName: "book", keywords: ["教育学习", "education", "learning", "tutorial", "course"]),
        CategoryRule(id: "social", name: "Social", symbolName: "person.2", keywords: ["社交网络", "social", "chat", "messaging", "communication"]),
        CategoryRule(id: "analytics", name: "Analytics", symbolName: "chart.bar", keywords: ["数据分析", "analytics", "data", "visualization", "chart"])
    ]

    static func name(for id: String?) -> String {
        guard let id else { return AppLocalizer.text("Auto Category") }
        if id == uncategorizedId { return AppLocalizer.text("Uncategorized") }
        let name = defaults.first(where: { $0.id == id })?.name ?? "Auto Category"
        return AppLocalizer.text(name)
    }
}

enum CategoryResolver {
    static func resolvedCategoryId(for repo: StarredRepo) -> String? {
        if let manualCategoryId = repo.manualCategoryId, !manualCategoryId.isEmpty {
            return manualCategoryId
        }
        return defaultCategoryId(for: repo)
    }

    static func defaultCategoryId(for repo: StarredRepo) -> String? {
        let searchText = [
            repo.name,
            repo.fullName,
            repo.descriptionText ?? "",
            repo.language ?? "",
            repo.topics.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()

        return CategoryRule.defaults.first { category in
            category.keywords.contains { keyword in
                searchText.contains(keyword.lowercased())
            }
        }?.id
    }

    static func matches(repo: StarredRepo, selectedCategoryId: String?) -> Bool {
        guard let selectedCategoryId, selectedCategoryId != RepositoryFilter.allCategoryId else {
            return true
        }
        let resolved = resolvedCategoryId(for: repo)
        if selectedCategoryId == CategoryRule.uncategorizedId {
            return resolved == nil || resolved == CategoryRule.uncategorizedId
        }
        return resolved == selectedCategoryId
    }
}
