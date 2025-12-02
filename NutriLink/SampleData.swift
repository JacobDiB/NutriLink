//
//  SampleData.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/23/25.
//

import Foundation
import SwiftData

// Helper for preloading demo users, coaches, and logs into SwiftData
struct SampleData {
    
    // Remove all existing users, coaches, and logs
    static func clearAllData(modelContext: ModelContext) throws {
        let allUsers = try modelContext.fetch(FetchDescriptor<UserAccount>())
        allUsers.forEach { modelContext.delete($0) }

        let allCoaches = try modelContext.fetch(FetchDescriptor<CoachAccount>())
        allCoaches.forEach { modelContext.delete($0) }

        let allLogs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        allLogs.forEach { modelContext.delete($0) }

        try modelContext.save()
    }

    // Only preload data if the store is empty
    static func preloadIfNeeded(modelContext: ModelContext) async {
        do {
            let existingUsers = try modelContext.fetch(FetchDescriptor<UserAccount>())
            let existingCoaches = try modelContext.fetch(FetchDescriptor<CoachAccount>())

            if !existingUsers.isEmpty || !existingCoaches.isEmpty {
                return
            }

            try clearAllData(modelContext: modelContext)

            // Generate 30 days of random logs for a sample user
            func generateMonthOfLogs() -> [DailyLog] {
                let cal = Calendar.current
                return (0..<30).map { offset in
                    let date = cal.date(byAdding: .day, value: -offset, to: Date())!
                    let calories = Int.random(in: 1800...2400)
                    return DailyLog(date: date, calories: calories)
                }
            }

            let coachSarah = CoachAccount(
                email: "sarah.coach@nutrilink.com",
                password: "password123",
                name: "Sarah Johnson"
            )

            let coachMike = CoachAccount(
                email: "mike.t@nutrilink.com",
                password: "pass456",
                name: "Mike Thompson"
            )

            let emily = UserAccount(
                email: "emily@example.com",
                password: "emily123",
                username: "EmilyFit",
                dailyLogs: generateMonthOfLogs(),
                goalCalories: "1700",
                coach: coachSarah
            )

            let jason = UserAccount(
                email: "jason@example.com",
                password: "jason456",
                username: "JasonStrength",
                dailyLogs: generateMonthOfLogs(),
                goalCalories: "2400",
                coach: coachSarah
            )

            let anna = UserAccount(
                email: "anna@example.com",
                password: "anna789",
                username: "AnnaRunner",
                dailyLogs: generateMonthOfLogs(),
                goalCalories: "1800",
                coach: coachMike
            )

            let tom = UserAccount(
                email: "tom@example.com",
                password: "tom321",
                username: "TomBulk",
                dailyLogs: generateMonthOfLogs(),
                goalCalories: "2800",
                coach: coachMike
            )

            coachSarah.clients = [emily, jason]
            coachSarah.bio = "Certified nutritionist and personal trainer with 6 years of experience."

            coachMike.clients = [anna, tom]
            coachMike.bio = "Strength coach specializing in muscle building and athletic performance."

            modelContext.insert(coachSarah)
            modelContext.insert(coachMike)
            modelContext.insert(emily)
            modelContext.insert(jason)
            modelContext.insert(anna)
            modelContext.insert(tom)

            try modelContext.save()

        } catch {
            // Ignore preload errors in production sample data
        }
    }
}

