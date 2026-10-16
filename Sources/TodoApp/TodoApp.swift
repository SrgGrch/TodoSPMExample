import SwiftUI

@main
struct TodoApp: App {
    @State private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            TodoListView()
                .environment(store)
        }
    }
}
