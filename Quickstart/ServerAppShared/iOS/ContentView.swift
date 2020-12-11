import Shared
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(SharedStruct.text)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
