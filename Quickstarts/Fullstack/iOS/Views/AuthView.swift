import SwiftUI

struct AuthView: View {
    @State var name: String = ""
    @State var email: String = ""
    @State var password: String = ""
    @State var isLogin: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                Text(self.isLogin ? "Login" : "Signup")
                    .font(.title)
                if !self.isLogin {
                    TextField("Your name", text: self.$name).field()
                }
                TextField("Email", text: self.$email).field()
                SecureField("Password", text: self.$password).field()
            }.padding()
            VStack {
                Button(self.isLogin ? "Login" : "Signup", action: self.isLogin ? self.login : self.signup)
                    .padding(.bottom)
                Button(self.isLogin ? "Signup instead" : "Login instead") {
                    self.isLogin.toggle()
                }
            }.padding()
        }
        .alert(isPresented: self.$showAlert) {
            Alert(title: Text("Invalid info"), message: Text("Ensure all fields are filled in."))
        }
    }
    
    func login() {
        guard !self.email.isEmpty && !self.password.isEmpty else {
            self.showAlert = true
            return
        }
        
        Storage.shared.login(email: self.email, password: self.password)
    }
    
    func signup() {
        guard !self.name.isEmpty && !self.email.isEmpty && !self.password.isEmpty else {
            self.showAlert = true
            return
        }
        
        Storage.shared.signup(name: self.name, email: self.email, password: self.password)
    }
}

extension View {
    func field() -> some View {
        self.padding(.leading, 24)
            .frame(height: 54)
            .background(Color(red: 0.925, green: 0.941, blue: 0.945))
            .cornerRadius(4)
    }
}
