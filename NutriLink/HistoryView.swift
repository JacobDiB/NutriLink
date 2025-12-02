//
//  HistoryView.swift
//  NutriLink
//
//  Created by CS3714 on 12/2/25.
//

import SwiftUI

// Shows previous logs for the signed-in user
struct HistoryView: View {
    @EnvironmentObject var auth: AuthState

    // Most recent days appear first
    private var sortedLogs: [DailyLog] {
        guard let logs = auth.currentUser?.dailyLogs else { return [] }
        return logs.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedLogs.isEmpty {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedLogs) { log in
                        Section(header: logHeader(log)) {
                            if log.foodEntries.isEmpty {
                                Text("No detailed foods logged for this day.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(log.foodEntries.sorted(by: { $0.date < $1.date })) { entry in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.name)
                                        }
                                        Spacer()
                                        Text("\(entry.calories) kcal")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    // Displays date + total calories for a log section
    private func logHeader(_ log: DailyLog) -> some View {
        let dateString = log.date.formatted(date: .abbreviated, time: .omitted)
        return HStack {
            Text(dateString)
            Spacer()
            Text("\(log.calories) kcal")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AuthState())
}

