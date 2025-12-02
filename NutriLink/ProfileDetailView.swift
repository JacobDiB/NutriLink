//
//  ProfileDetailView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

// ProfileDetailView.swift
import SwiftUI
import Charts

struct ProfileDetailView: View {
    @EnvironmentObject var auth: AuthState

    private var yearlyLogs: [DailyLog] {
        guard let logs = auth.currentUser?.dailyLogs else { return [] }
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        return logs
            .filter { $0.date >= yearAgo }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(auth.currentUser?.username ?? "")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(auth.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // MARK: Yearly Progress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress (Past Month)")
                            .font(.title2.bold())

                        if yearlyLogs.isEmpty {
                            Text("No logs recorded yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(yearlyLogs.count)")
                            Chart(yearlyLogs) { item in
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

                    // MARK: Goals Section
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
                    }

                    // MARK: Trainer Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trainer")
                            .font(.title2.bold())

                        Text(auth.currentUser?.coach?.name ?? "No assigned trainer")
                            .font(.body)
                            .foregroundStyle(.secondary)
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
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
}

