//
//  SearchView.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/15/25.
//

// SearchView.swift
import SwiftUI

struct LogView: View {
    @State private var query: String = ""
    @State private var results: [FatSecretFoodSearchResponse.Foods.Food] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: Search Bar
                TextField("Search foods...", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                // Optional: a search button for simulator testing
                Button("Search") {
                    Task {
                        await performSearch()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)

                // MARK: Loading / Error
                if isLoading {
                    ProgressView("Searching…")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // MARK: Results List
                List(results) { food in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name)
                            .font(.headline)

                        if let brand = food.brand,
                            !brand.isEmpty {
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

                Spacer()
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
            print("foods: " + "\(foods[0])")
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
}
