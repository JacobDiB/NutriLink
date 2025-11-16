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
    @State private var progressData: [DailyProgress] = [
        .init(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, calories: 1800),
        .init(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, calories: 2000),
        .init(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, calories: 2200),
        .init(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, calories: 1950),
        .init(date: Date(), calories: 2100)
    ]

    @AppStorage("goalCalories") private var goalCalories: String = "2200"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.title2.bold())

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

                // MARK: Goals Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goals")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Calorie Goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Goal", text: $goalCalories)
                            .disabled(true)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // MARK: Trainer Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trainer")
                        .font(.title2.bold())

                    Text("Assigned Trainer: Sarah Johnson")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
    }
}

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
}
