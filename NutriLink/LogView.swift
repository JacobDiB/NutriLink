//
//  LogView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

import SwiftUI
import SwiftData

struct LogView: View {
    @EnvironmentObject var auth: AuthState
    @Environment(\.modelContext) private var modelContext

    @State private var query: String = ""
    @State private var results: [FatSecretFoodSearchResponse.Foods.Food] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var todayLog: DailyLog? {
        guard let user = auth.currentUser else { return nil }
        let calendar = Calendar.current
        return user.dailyLogs.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    private var todayEntries: [FoodEntry] {
        guard let log = todayLog else { return [] }
        return log.foodEntries.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Search foods...", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                Button("Search") {
                    Task {
                        await performSearch()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)

                if isLoading {
                    ProgressView("Searching…")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                List {
                    if !todayEntries.isEmpty {
                        Section("Today's foods") {
                            ForEach(todayEntries) { entry in
                                HStack {
                                    Text(entry.name)
                                    Spacer()
                                    Text("\(entry.calories) kcal")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete(perform: deleteEntries)
                        }
                    }

                    Section("Search results") {
                        ForEach(results) { food in
                            Button {
                                logFood(food)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.name)
                                        .font(.headline)

                                    if let brand = food.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    if let desc = food.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log")
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let foods = try await FatSecretAPI.shared.searchFoods(query: trimmed)
            results = foods
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }

    private func logFood(_ food: FatSecretFoodSearchResponse.Foods.Food) {
        guard let user = auth.currentUser else {
            errorMessage = "No logged-in user."
            return
        }

        guard
            let serving = food.servings?.serving.first,
            let calString = serving.calories,
            let calDouble = Double(calString)
        else {
            errorMessage = "No calorie info available for this item."
            return
        }

        let caloriesToAdd = Int(calDouble.rounded())
        let calendar = Calendar.current
        let today = Date()

        let log: DailyLog
        if let existing = user.dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            log = existing
        } else {
            log = DailyLog(date: today, calories: 0)
            user.dailyLogs.append(log)
            modelContext.insert(log)
        }

        log.calories += caloriesToAdd

        let entry = FoodEntry(
            name: food.name,
            calories: caloriesToAdd,
            date: today,
            dailyLog: log
        )
        log.foodEntries.append(entry)
        modelContext.insert(entry)

        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save log."
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entries = todayEntries
        for index in offsets {
            let entry = entries[index]
            if let log = entry.dailyLog {
                log.calories -= entry.calories
            }
            modelContext.delete(entry)
        }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete entry."
        }
    }
}

#Preview {
    NavigationStack {
        LogView()
            .environmentObject(AuthState())
    }
}

