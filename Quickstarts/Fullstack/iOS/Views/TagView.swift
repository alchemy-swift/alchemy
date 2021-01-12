import SwiftUI

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
