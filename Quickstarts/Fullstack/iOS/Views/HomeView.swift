import Foundation
import SwiftUI

struct HomeView: View {
    private enum Create: Int, Identifiable {
        case todo, tag
        var id: Int { self.rawValue }
    }
    
    @State private var showActionSheet: Bool = false
    @State private var create: Create? = nil
    
    @ObservedObject
    private var storage = Storage.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(self.storage.todos) { todo in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(todo.name)
                                    .font(.title2)
                                HStack {
                                    ForEach(todo.tags) {
                                        TagView(tag: $0, isSelected: true)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: todo.isComplete ? "checkmark.square": "square")
                        }
                        .padding(5.0)
                        .background(Color.white)
                        .onTapGesture {
                            self.toggle(todo: todo)
                        }
                    }
                    .onDelete(perform: self.delete)
                }
                .listStyle(InsetGroupedListStyle())
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ActionButton { self.showActionSheet = true }
                    }
                }
            }
            .navigationTitle("Your Todos")
            .onAppear {
                self.storage.getTodos()
                self.storage.getTags()
            }
            .actionSheet(isPresented: self.$showActionSheet) {
                ActionSheet(
                    title: Text("Create"),
                    buttons: [
                        .default(Text("Todo")) { self.create = .todo },
                        .default(Text("Tag")) { self.create = .tag },
                        .cancel(Text("Cancel")),
                    ])
            }
            .sheet(
                item: self.$create,
                onDismiss: {
                    self.create = nil
                },
                content: { item in
                    switch item {
                    case .tag: CreateTagView()
                    case .todo: CreateTodoView()
                }
            })
        }
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let todo = self.storage.todos.remove(at: index)
            self.storage.deleteTodo(todo)
        }
    }
    
    private func toggle(todo: Todo) {
        self.storage.completeTodo(todo)
    }
}
