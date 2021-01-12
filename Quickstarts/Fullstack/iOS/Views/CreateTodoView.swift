import SwiftUI

struct CreateTodoView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var tags: [Tag] = []
    
    @ObservedObject
    private var storage = Storage.shared
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Name", text: self.$name).field()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())]) {
                        ForEach(self.storage.tags) { tag in
                            TagView(tag: tag, isSelected: self.tags.contains(where: { $0.id == tag.id }))
                                .onTapGesture {
                                    if self.tags.contains(where: { $0.id == tag.id }) {
                                        self.tags.removeAll(where: { $0.id == tag.id })
                                    } else {
                                        self.tags.append(tag)
                                    }
                                }
                        }
                    }
                }
                Spacer()
                Button("Create", action: self.createTodo)
            }
            .padding()
            .navigationTitle("Create Todo")
        }
    }
    
    private func createTodo() {
        guard !self.name.isEmpty else {
            return
        }
        
        self.storage.createTodo(name: self.name, tags: self.tags)
        self.presentationMode.wrappedValue.dismiss()
    }
}
