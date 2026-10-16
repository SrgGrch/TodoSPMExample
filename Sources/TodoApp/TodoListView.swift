import SwiftUI
import Defaults
import ConfettiSwiftUI
import Kingfisher

struct TodoListView: View {
    @Environment(TodoStore.self) private var store
    @Default(.hideCompleted) private var hideCompleted
    @Default(.sortOrder) private var sortOrder
    @State private var newTitle = ""
    @State private var confetti = 0
    @FocusState private var inputFocused: Bool

    private var visibleTodos: [Todo] {
        let filtered = store.todos.filter { !hideCompleted || !$0.isDone }
        switch sortOrder {
        case .newestFirst: return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst: return filtered.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical: return filtered.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New todo", text: $newTitle)
                            .focused($inputFocused)
                            .submitLabel(.done)
                            .onSubmit(addTodo)
                        Button("Add", systemImage: "plus.circle.fill", action: addTodo)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    ForEach(visibleTodos) { todo in
                        TodoRow(todo: todo) {
                            if store.toggle(todo.id) { confetti += 1 }
                        }
                    }
                    .onDelete { offsets in
                        store.delete(offsets.map { visibleTodos[$0].id })
                    }
                } footer: {
                    let left = store.todos.filter { !$0.isDone }.count
                    Text("\(left) of \(store.todos.count) left")
                }
            }
            .overlay {
                if store.todos.isEmpty {
                    EmptyStateView()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("ToDo")
            .toolbar { toolbar }
            .confettiCannon(trigger: $confetti, num: 40)
            .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Hide keyboard", systemImage: "keyboard.chevron.compact.down") {
                inputFocused = false
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            if store.isLoading {
                ProgressView()
            } else {
                Button("Import", systemImage: "icloud.and.arrow.down") {
                    Task { await store.importSamples() }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Settings", systemImage: "line.3.horizontal.decrease.circle") {
                Toggle("Hide completed", isOn: $hideCompleted)
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { Text($0.title).tag($0) }
                }
                Divider()
                Button("Delete completed", systemImage: "trash", role: .destructive) {
                    store.clearCompleted()
                }
            }
        }
    }

    private func addTodo() {
        store.add(newTitle)
        newTitle = ""
        inputFocused = true
    }
}

private struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isDone ? .green : .secondary)
                    .font(.title3)
                VStack(alignment: .leading) {
                    Text(todo.title)
                        .strikethrough(todo.isDone)
                        .foregroundStyle(todo.isDone ? .secondary : .primary)
                    Text(todo.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Remote image loaded and cached by Kingfisher.
            KFImage(URL(string: "https://picsum.photos/seed/todo/200"))
                .placeholder { ProgressView() }
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            Text("No todos yet")
                .font(.headline)
            Text("Add your first one or import some samples")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
