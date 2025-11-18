// iphone 17 pro

import SwiftUI
import Combine
import Charts


// role type for login
enum UserRole {
    case user
    case coach
}

// main app view
struct ContentView: View {
    @StateObject private var auth = AuthState()
    var body: some View {
        Group {
            if auth.isLoggedIn {
                // show different main views based on role
                if auth.role == .coach {
                    CoachMainTabView()
                        .environmentObject(auth)
                } else {
                    MainTabView()
                        .environmentObject(auth)
                }
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
    @Published var role: UserRole = .user

    // singing in
    func signIn(email: String, password: String, asCoach: Bool) {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Enter email and password"
            return
        }
        userEmail = email
        role = asCoach ? .coach : .user
        isLoggedIn = true
        error = nil
    }

    // singing out
    func signOut() {
        isLoggedIn = false
        userEmail = ""
        role = .user
    }
}

// login screen
struct LoginView: View {
    @EnvironmentObject var auth: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isCoach = false

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
                Toggle("Sign in as Coach", isOn: $isCoach)
            }

            // sign in button
            Button {
                auth.signIn(email: email, password: password, asCoach: isCoach)
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
                auth.signIn(email: "guest@local", password: "guest", asCoach: false)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}

// main app view for user
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

// main app view after login page for coach
struct CoachMainTabView: View {
    var body: some View {
        TabView {
            CoachHomeView()
                .tabItem { Label("Coach Home", systemImage: "person.2.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

// home screen
struct HomeView: View {
    @AppStorage("goalCalories") private var goalCalories: String = "2200"
    
    @State private var progressData: [DailyProgress] = [
        .init(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, calories: 1800),
        .init(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, calories: 2000),
        .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, calories: 2200),
        .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, calories: 1950),
        .init(date: Date(), calories: 2100)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome to NutriLink")
                            .font(.title2.bold())
                        Text("Track meals and goals easily.")
                            .foregroundStyle(.secondary)
                    }
                    
                    // MARK: Progress Section (DIRECTLY ON HOME)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Weekly Progress")
                            .font(.headline)
                        
                        Chart(progressData) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Calories", item.calories)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.cardinal)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // MARK: Goal Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.headline)
                        
                        Text(goalCalories)
                            .font(.title3.bold())
                            .padding(.vertical, 4)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

    
// coach home screen
struct CoachHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Coach Dashboard")
                    .font(.title2)
                    .bold()
                Text("Here coaches will see client info and messages.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Coach")
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
