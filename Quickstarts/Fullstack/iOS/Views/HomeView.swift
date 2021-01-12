import Foundation
import SwiftUI

struct HomeView: View {
    enum Create: Int, Identifiable {
        case todo, tag
        var id: Int { self.rawValue }
    }
    
    @State var showActionSheet: Bool = false
    @State var create: Create? = nil
    
    @ObservedObject
    var storage = Storage.shared
    
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
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let todo = self.storage.todos.remove(at: index)
            self.storage.deleteTodo(todo)
        }
    }
    
    func toggle(todo: Todo) {
        self.storage.completeTodo(todo)
    }
}

struct TagView: View {
    let tag: Tag
    let isSelected: Bool
    
    var body: some View {
        Text(self.tag.name)
            .font(.subheadline)
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .background(self.tag.color.color)
            .cornerRadius(20.0)
            .opacity(self.isSelected ? 1 : 0.2)
    }
}

struct ActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(
            action: self.action,
            label: {
                Text("+")
                    .font(.system(.largeTitle))
                    .frame(width: 77, height: 70)
                    .foregroundColor(Color.white)
                    .padding(.bottom, 7)
            }
        )
        .background(Color.blue)
        .cornerRadius(38.5)
        .padding()
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 3, y: 3)
    }
}
