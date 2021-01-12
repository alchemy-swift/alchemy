import SwiftUI

struct CreateTagView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name: String = ""
    @State private var color = TagColor.red
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Name", text: self.$name).field()
                HStack {
                    ForEach(TagColor.allCases) { tagColor in
                        Text(tagColor.name.capitalized)
                            .font(.caption)
                            .padding()
                            .background(tagColor.color)
                            .cornerRadius(3.0)
                            .opacity(tagColor == self.color ? 1 : 0.2)
                            .onTapGesture { self.color = tagColor }
                    }
                }
                Spacer()
                Button("Create", action: self.createTag)
            }
            .padding()
            .navigationTitle("Create Tag")
        }
    }
    
    private func createTag() {
        guard !self.name.isEmpty else {
            return
        }
        
        Storage.shared.createTag(name: self.name, color: self.color)
        self.presentationMode.wrappedValue.dismiss()
    }
}

extension TagColor: Identifiable {
    public var id: Int {
        self.rawValue
    }
    
    var color: Color {
        switch self {
        case .blue:   return Color.blue
        case .green:  return Color.green
        case .purple: return Color.purple
        case .orange: return Color.orange
        case .red:    return Color.red
        }
    }
    
    var name: String {
        switch self {
        case .blue:   return "blue"
        case .green:  return "green"
        case .purple: return "purple"
        case .orange: return "orange"
        case .red:    return "red"
        }
    }
}
