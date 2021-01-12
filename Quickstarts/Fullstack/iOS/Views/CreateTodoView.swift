import SwiftUI

struct CreateTodoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var name: String = ""
    @State var tags: [Tag] = []
    
    @ObservedObject
    var storage = Storage.shared
    
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
    
    func createTodo() {
        guard !self.name.isEmpty else {
            return
        }
        
        self.storage.createTodo(name: self.name, tags: self.tags)
        self.presentationMode.wrappedValue.dismiss()
    }
}
