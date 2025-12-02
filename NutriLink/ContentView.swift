// iphone 17 pro

import SwiftUI
import SwiftData
import Combine
import Charts


// role type for login
enum UserRole {
    case user
    case coach
}

// main app view
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var auth = AuthState()

    var body: some View {
        Group {
            if auth.isLoggedIn {
                if auth.currentCoach != nil {
                    CoachMainTabView()
                        .environmentObject(auth)
                } else if auth.currentUser != nil {
                    MainTabView()
                        .environmentObject(auth)
                }
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
        .task {
            await SampleData.preloadIfNeeded(modelContext: modelContext)
        }
    }
}

// stores login info
@MainActor
final class AuthState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserAccount?
    @Published var currentCoach: CoachAccount?
    @Published var error: String?

    // Signs in using SwiftData lookup
    func signIn(email: String, password: String, modelContext: ModelContext) async {
        error = nil

        let loginEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let loginPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // Debug: list all accounts visible to this context
            let allUsers = try modelContext.fetch(FetchDescriptor<UserAccount>())
            let allCoaches = try modelContext.fetch(FetchDescriptor<CoachAccount>())
            
            // Try user login
            let userDescriptor = FetchDescriptor<UserAccount>(
                predicate: #Predicate { user in
                    user.email == loginEmail &&
                    user.password == loginPassword
                }
            )

            if let user = try modelContext.fetch(userDescriptor).first {
                self.currentUser = user
                self.currentCoach = nil
                self.isLoggedIn = true
                print("DEBUG AuthState – logged in as USER \(user.email)")
                return
            }

            // Try coach login
            let coachDescriptor = FetchDescriptor<CoachAccount>(
                predicate: #Predicate { coach in
                    coach.email == loginEmail &&
                    coach.password == loginPassword
                }
            )

            if let coach = try modelContext.fetch(coachDescriptor).first {
                self.currentCoach = coach
                self.currentUser = nil
                self.isLoggedIn = true
                print("DEBUG AuthState – logged in as COACH \(coach.email)")
                return
            }

            // No match → error
            self.error = "Invalid email or password"
            self.isLoggedIn = false
            print("DEBUG AuthState – no match for \(loginEmail)")

        } catch {
            self.error = "Login failed: \(error.localizedDescription)"
            self.isLoggedIn = false
            print("DEBUG AuthState – signIn error: \(error)")
        }
    }


    // Signs out and clears state
    func signOut() {
        self.currentUser = nil
        self.currentCoach = nil
        self.isLoggedIn = false
        self.error = nil
    }
}

// login screen
struct LoginView: View {
    @EnvironmentObject var auth: AuthState
    @Environment(\.modelContext) private var modelContext

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text("NutriLink")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                HStack {
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

            Button {
                Task {
                    await auth.signIn(email: email,
                                      password: password,
                                      modelContext: modelContext)
                }
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty)

            if let e = auth.error {
                Text(e).foregroundColor(.red)
            }

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

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }

            ProfileDetailView()
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
            CoachProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

// home screen
struct HomeView: View {
    @EnvironmentObject var auth: AuthState
    @AppStorage("goalCalories") private var goalCalories: String = "2200"

    // We compute the user's last 7 days of logs
    private var recentLogs: [DailyLog] {
        guard let logs = auth.currentUser?.dailyLogs else { return [] }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        return logs
            .filter { $0.date >= weekAgo }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome to NutriLink, \(auth.currentUser?.username ?? "User")")
                            .font(.title2.bold())
                        Text("Track meals and goals easily.")
                            .foregroundStyle(.secondary)
                    }

                    // MARK: Weekly Progress
                    if !recentLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Weekly Progress")
                                .font(.headline)

                            Chart(recentLogs) { item in
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
                    } else {
                        Text("No logs recorded for this week.")
                            .foregroundStyle(.secondary)
                    }

                    // MARK: Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.headline)

                        Text(auth.currentUser?.goalCalories ?? "Not set")
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
    @EnvironmentObject var auth: AuthState

    private var coach: CoachAccount? {
        auth.currentCoach
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back, \(coach?.name ?? "Coach")")
                            .font(.title.bold())
                        Text("Here is an overview of your clients.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // MARK: Client List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Clients")
                            .font(.title2.bold())

                        if let clients = coach?.clients, !clients.isEmpty {
                            ForEach(clients, id: \.email) { client in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(client.username)
                                        .font(.headline)
                                    Text(client.email)
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)

                                    // Optional: recent average calories
                                    if let avg = averageCalories(for: client) {
                                        Text("Avg. calories (7 days): \(avg)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Text("No clients assigned yet.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Coach Dashboard")
        }
    }

    // MARK: Helper — calculate weekly average
    func averageCalories(for user: UserAccount) -> Int? {
        let logs = user.dailyLogs.sorted { $0.date > $1.date }
        let last7 = logs.prefix(7)
        guard !last7.isEmpty else { return nil }
        let avg = last7.map { $0.calories }.reduce(0, +) / last7.count
        return avg
    }
}


// coach profile tab
struct CoachProfileView: View {
    @EnvironmentObject var auth: AuthState

    private var coach: CoachAccount? {
        auth.currentCoach
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile")
                            .font(.largeTitle.bold())
                        Text(coach?.name ?? "Coach")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(coach?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: Bio Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bio")
                            .font(.title2.bold())

                        Text(coach?.bio.isEmpty == true ? "No bio available." : coach?.bio ?? "")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // MARK: Settings / Sign Out
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Actions")
                            .font(.title2.bold())

                        Button(role: .destructive) {
                            auth.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Coach Profile")
        }
    }
}

#Preview {
    ContentView()
            .modelContainer(for: [
                UserAccount.self,
                CoachAccount.self,
                DailyLog.self
            ], inMemory: true)
}
