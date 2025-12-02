//  ProfileDetailView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

import SwiftUI
import Charts
import SwiftData

// Shows user profile, goals, macros, coach connection, and coach notes
struct ProfileDetailView: View {
    @EnvironmentObject var auth: AuthState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CoachAccount.name) private var allCoaches: [CoachAccount]

    // Logs for the past month for the current user
    private var monthlyLogs: [DailyLog] {
        guard let logs = auth.currentUser?.dailyLogs else { return [] }
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return logs
            .filter { $0.date >= monthAgo }
            .sorted { $0.date < $1.date }
    }

    // Today's DailyLog, if one exists
    private var todayLog: DailyLog? {
        guard let user = auth.currentUser else { return nil }
        let calendar = Calendar.current
        return user.dailyLogs.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    // Sum of today's macros from all food entries
    private var todayMacros: (protein: Double, carbs: Double, fat: Double) {
        guard let log = todayLog else { return (0, 0, 0) }
        let protein = log.foodEntries.reduce(0) { $0 + $1.protein }
        let carbs = log.foodEntries.reduce(0) { $0 + $1.carbs }
        let fat = log.foodEntries.reduce(0) { $0 + $1.fat }
        return (protein, carbs, fat)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Basic user info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(auth.currentUser?.username ?? "")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(auth.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Calorie progress chart for the past month
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress (Past Month)")
                            .font(.title2.bold())

                        if monthlyLogs.isEmpty {
                            Text("No logs recorded yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            Chart(monthlyLogs) { item in
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
                    }

                    // Goals and today's macros
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Goals")
                            .font(.title2.bold())

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Calorie Goal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(auth.currentUser?.goalCalories ?? "Not set")
                                .font(.title3.bold())
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Macro Goals")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Protein: \(auth.currentUser?.goalProtein.isEmpty == false ? auth.currentUser!.goalProtein : "-") g")
                            Text("Carbs: \(auth.currentUser?.goalCarbs.isEmpty == false ? auth.currentUser!.goalCarbs : "-") g")
                            Text("Fat: \(auth.currentUser?.goalFat.isEmpty == false ? auth.currentUser!.goalFat : "-") g")
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Macros")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Protein: \(Int(todayMacros.protein)) g")
                            Text("Carbs: \(Int(todayMacros.carbs)) g")
                            Text("Fat: \(Int(todayMacros.fat)) g")
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Connect / disconnect from a coach
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trainer")
                            .font(.title2.bold())

                        if let user = auth.currentUser {
                            if let coach = user.coach {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(coach.name)
                                        .font(.body)
                                    Text(coach.email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Button(role: .destructive) {
                                        disconnectCoach(for: user)
                                    } label: {
                                        Text("Disconnect from coach")
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    if allCoaches.isEmpty {
                                        Text("No coaches available.")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Connect to a coach:")
                                            .font(.subheadline)
                                        ForEach(allCoaches, id: \.email) { coach in
                                            Button {
                                                connect(user: user, to: coach)
                                            } label: {
                                                HStack {
                                                    Text(coach.name)
                                                    Spacer()
                                                    Text(coach.email)
                                                        .foregroundStyle(.secondary)
                                                        .font(.caption)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }

                    // Read-only view of coach meal plan and notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coach Meal Plan & Notes")
                            .font(.title2.bold())

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Plan")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(auth.currentUser?.mealPlan.isEmpty == false ? auth.currentUser!.mealPlan : "No meal plan yet.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Coach Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(auth.currentUser?.coachNotes.isEmpty == false ? auth.currentUser!.coachNotes : "No notes yet.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Sign-out button
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
        }
    }

    // Connect current user to a coach and keep clients list in sync
    private func connect(user: UserAccount, to coach: CoachAccount) {
        user.coach = coach
        if !coach.clients.contains(where: { $0.email == user.email }) {
            coach.clients.append(user)
        }
        do {
            try modelContext.save()
        } catch {
        }
    }

    // Remove coach from user and remove user from the coach's clients list
    private func disconnectCoach(for user: UserAccount) {
        if let coach = user.coach {
            coach.clients.removeAll { $0.email == user.email }
        }
        user.coach = nil
        do {
            try modelContext.save()
        } catch {
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
            .environmentObject(AuthState())
    }
}

