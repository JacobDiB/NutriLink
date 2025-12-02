//
//  LogView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

import SwiftUI
import SwiftData

// Lets the user search foods, log them, and see today's entries
struct LogView: View {
    @EnvironmentObject var auth: AuthState
    @Environment(\.modelContext) private var modelContext

    @State private var query: String = ""
    @State private var results: [FatSecretFoodSearchResponse.Foods.Food] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var logMessage: String?

    @State private var selectedFood: FatSecretFoodSearchResponse.Foods.Food?
    @State private var selectedServings: [FatSecretFoodSearchResponse.Foods.Food.Serving] = []
    @State private var showingServingSheet = false

    // DailyLog for today, if it exists
    private var todayLog: DailyLog? {
        guard let user = auth.currentUser else { return nil }
        let calendar = Calendar.current
        return user.dailyLogs.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }

    // Food entries for today, sorted by time
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
                    .disabled(isLoading)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                Button("Search") {
                    Task { await performSearch() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || query.trimmingCharacters(in: .whitespaces).isEmpty)

                if isLoading {
                    ProgressView("Searching…")
                }

                if let logMessage {
                    Text(logMessage)
                        .foregroundStyle(.green)
                        .padding(.horizontal)
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
                                handleFoodTap(food)
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
            .sheet(isPresented: $showingServingSheet) {
                servingPickerSheet()
            }
        }
    }

    // Call the API and refresh the search results
    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        logMessage = nil

        do {
            let foods = try await FatSecretAPI.shared.searchFoods(query: trimmed)
            results = foods
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }

    // Handle tapping a food: either log immediately or show a serving picker
    private func handleFoodTap(_ food: FatSecretFoodSearchResponse.Foods.Food) {
        guard let servings = food.servings?.serving, !servings.isEmpty else {
            errorMessage = "No serving info available for this item."
            return
        }

        if servings.count == 1 {
            logFood(food, serving: servings[0])
        } else {
            selectedFood = food
            selectedServings = servings
            showingServingSheet = true
        }
    }

    // Sheet that lets the user choose which serving size to log
    private func servingPickerSheet() -> some View {
        NavigationStack {
            List {
                ForEach(selectedServings.indices, id: \.self) { index in
                    let serving = selectedServings[index]
                    Button {
                        if let food = selectedFood {
                            logFood(food, serving: serving)
                        }
                        showingServingSheet = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(serving.servingDescription ?? "Serving \(index + 1)")
                            if let calories = serving.calories {
                                Text("\(calories) kcal")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                            if let amount = serving.metricServingAmount,
                               let unit = serving.metricServingUnit {
                                Text("\(amount) \(unit)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Serving")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingServingSheet = false
                    }
                }
            }
        }
    }

    // Add a food entry to today's log, including macros
    private func logFood(
        _ food: FatSecretFoodSearchResponse.Foods.Food,
        serving: FatSecretFoodSearchResponse.Foods.Food.Serving
    ) {
        guard let user = auth.currentUser else {
            errorMessage = "No logged-in user."
            return
        }

        guard let calString = serving.calories,
              let calDouble = Double(calString) else {
            errorMessage = "No calorie info available for this serving."
            return
        }

        let protein = Double(serving.protein ?? "") ?? 0
        let carbs = Double(serving.carbohydrate ?? "") ?? 0
        let fat = Double(serving.fat ?? "") ?? 0

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
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: today,
            dailyLog: log
        )
        log.foodEntries.append(entry)
        modelContext.insert(entry)

        do {
            try modelContext.save()
            errorMessage = nil
            logMessage = "Logged \(caloriesToAdd) kcal from \(food.name)"
        } catch {
            errorMessage = "Failed to save log."
        }
    }

    // Delete selected entries from today's log and adjust calories
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

