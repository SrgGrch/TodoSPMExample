import Foundation
import Observation
import IdentifiedCollections
import Alamofire

@MainActor
@Observable
final class TodoStore {
    private(set) var todos: IdentifiedArrayOf<Todo> = []
    var isLoading = false
    var errorMessage: String?

    private let fileURL = URL.documentsDirectory.appending(path: "todos.json")

    init() {
        load()
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todos.append(Todo(title: trimmed))
        save()
    }

    /// Returns true if the todo became completed.
    @discardableResult
    func toggle(_ id: Todo.ID) -> Bool {
        todos[id: id]?.isDone.toggle()
        save()
        return todos[id: id]?.isDone ?? false
    }

    func delete(_ ids: [Todo.ID]) {
        for id in ids { todos.remove(id: id) }
        save()
    }

    func clearCompleted() {
        todos.removeAll(where: \.isDone)
        save()
    }

    /// Imports sample todos from jsonplaceholder.typicode.com using Alamofire.
    func importSamples() async {
        struct RemoteTodo: Decodable {
            let title: String
            let completed: Bool
        }

        isLoading = true
        defer { isLoading = false }

        let response = await AF.request("https://jsonplaceholder.typicode.com/todos", parameters: ["_limit": 5])
            .validate()
            .serializingDecodable([RemoteTodo].self)
            .response

        switch response.result {
        case .success(let remote):
            for item in remote {
                todos.append(Todo(title: item.title, isDone: item.completed))
            }
            save()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Todo].self, from: data)
        else { return }
        todos = IdentifiedArray(uniqueElements: decoded)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(Array(todos))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
