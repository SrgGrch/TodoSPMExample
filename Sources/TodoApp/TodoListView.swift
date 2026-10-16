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
                        TextField("Новая задача", text: $newTitle)
                            .focused($inputFocused)
                            .submitLabel(.done)
                            .onSubmit(addTodo)
                        Button("Добавить", systemImage: "plus.circle.fill", action: addTodo)
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
                    Text("Осталось: \(left) из \(store.todos.count)")
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
            .alert("Ошибка", isPresented: .constant(store.errorMessage != nil)) {
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
            Button("Скрыть клавиатуру", systemImage: "keyboard.chevron.compact.down") {
                inputFocused = false
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            if store.isLoading {
                ProgressView()
            } else {
                Button("Импорт", systemImage: "icloud.and.arrow.down") {
                    Task { await store.importSamples() }
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Настройки", systemImage: "line.3.horizontal.decrease.circle") {
                Toggle("Скрыть выполненные", isOn: $hideCompleted)
                Picker("Сортировка", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { Text($0.title).tag($0) }
                }
                Divider()
                Button("Удалить выполненные", systemImage: "trash", role: .destructive) {
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
            Text("Задач пока нет")
                .font(.headline)
            Text("Добавьте первую или импортируйте примеры")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
