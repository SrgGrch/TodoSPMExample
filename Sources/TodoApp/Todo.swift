import Foundation
import Defaults

struct Todo: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isDone = false
    var createdAt = Date()
}

enum SortOrder: String, CaseIterable, Identifiable, Defaults.Serializable {
    case newestFirst, oldestFirst, alphabetical

    var id: Self { self }

    var title: String {
        switch self {
        case .newestFirst: "Newest first"
        case .oldestFirst: "Oldest first"
        case .alphabetical: "Alphabetical"
        }
    }
}

// Settings persisted via the Defaults library.
extension Defaults.Keys {
    static let hideCompleted = Key<Bool>("hideCompleted", default: false)
    static let sortOrder = Key<SortOrder>("sortOrder", default: .newestFirst)
}
