// iphone 17 pro

import SwiftUI
import Combine

// main app view
struct ContentView: View {
    @StateObject private var auth = AuthState()
    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()
                    .environmentObject(auth)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}

// stores login info
@MainActor
final class AuthState: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userEmail") var userEmail: String = ""
    @Published var error: String?

    // singing in
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Enter email and password"
            return
        }
        userEmail = email
        isLoggedIn = true
        error = nil
    }

    // singing out
    func signOut() {
        isLoggedIn = false
        userEmail = ""
    }
}

// login screen
struct LoginView: View {
    @EnvironmentObject var auth: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text("NutriLink")
                .font(.largeTitle)
                .bold()

            // email and password fields
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    // toggles between showing and hiding password
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }
                }
                .textFieldStyle(.roundedBorder)
            }

            // sign in button
            Button {
                auth.signIn(email: email, password: password)
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty)

            // invalid login text
            if let e = auth.error {
                Text(e).foregroundStyle(.red)
            }

            // guest login
            Button("Continue as Guest") {
                auth.signIn(email: "guest@local", password: "guest")
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}

// main app view after login page
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            LogView()
                .tabItem { Label("Log", systemImage: "plus.app") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

// home screen
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Welcome to NutriLink")
                    .font(.title2)
                    .bold()
                Text("Track meals and goals easily.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

// logging food screen
struct LogView: View {
    @State private var mealName = ""
    @State private var calories = ""
    @State private var meals: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Meal", text: $mealName)
                        .textFieldStyle(.roundedBorder)
                    TextField("kcal", text: $calories)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Button("Add") {
                        guard !mealName.isEmpty, !calories.isEmpty else { return }
                        meals.append("\(mealName) • \(calories) kcal")
                        mealName = ""
                        calories = ""
                    }
                }
                .padding(.horizontal)

                List(meals, id: \.self) { Text($0) }
            }
            .navigationTitle("Log")
        }
    }
}

// profile tab
struct ProfileView: View {
    @EnvironmentObject var auth: AuthState
    @AppStorage("userEmail") private var email: String = ""
    @AppStorage("goalCalories") private var goalCalories: String = "2200"

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text(email.isEmpty ? "Guest" : email)
                    Button("Sign Out") {
                        auth.signOut()
                    }
                    .foregroundStyle(.red)
                }

                Section("Daily Goal") {
                    TextField("Calories", text: $goalCalories)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview { ContentView() }


