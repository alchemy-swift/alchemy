import SwiftUI

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
