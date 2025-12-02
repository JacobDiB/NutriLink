//
//  SampleData.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/23/25.
//

import Foundation
import SwiftData

struct SampleData {
    
    static func clearAllData(modelContext: ModelContext) throws {
        // Delete all users
        let allUsers = try modelContext.fetch(FetchDescriptor<UserAccount>())
        allUsers.forEach { modelContext.delete($0) }

        // Delete all coaches
        let allCoaches = try modelContext.fetch(FetchDescriptor<CoachAccount>())
        allCoaches.forEach { modelContext.delete($0) }

        // Delete all daily logs
        let allLogs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        allLogs.forEach { modelContext.delete($0) }

        try modelContext.save()
    }

    static func preloadIfNeeded(modelContext: ModelContext) async {
        do {
            // Check if we already have any coaches OR users
//            let existingCoaches = try modelContext.fetch(FetchDescriptor<CoachAccount>())
//            let existingUsers   = try modelContext.fetch(FetchDescriptor<UserAccount>())
//
//            print("DEBUG SampleData – existing coaches: \(existingCoaches.count), users: \(existingUsers.count)")
//
//            if !existingCoaches.isEmpty || !existingUsers.isEmpty {
//                print("DEBUG SampleData – skipping preload, data already exists.")
//                return
//            }
            
            try clearAllData(modelContext: modelContext)

                    print("DEBUG SampleData – cleared old data.")

            // Helper: generate last 30 days of logs
            func generateMonthOfLogs() -> [DailyLog] {
                let cal = Calendar.current
                return (0..<30).map { offset in
                    let date = cal.date(byAdding: .day, value: -offset, to: Date())!
                    let calories = Int.random(in: 1800...2400)
                    return DailyLog(date: date, calories: calories)
                }
            }

            // Coaches
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

            // Users for Sarah
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

            coachSarah.clients = [emily, jason]
            coachSarah.bio = "Certified nutritionist and personal trainer with 6 years of experience."

            // Users for Mike
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

            coachMike.clients = [anna, tom]
            coachMike.bio = "Strength coach specializing in muscle building and athletic performance."


            // Insert everything
            modelContext.insert(coachSarah)
//            modelContext.insert(coachMike)
            modelContext.insert(emily)
            modelContext.insert(jason)
//            modelContext.insert(anna)
//            modelContext.insert(tom)

            try modelContext.save()

            // Debug: confirm we can read them right after save
            let usersAfter = try modelContext.fetch(FetchDescriptor<UserAccount>())
            let coachesAfter = try modelContext.fetch(FetchDescriptor<CoachAccount>())

            print("DEBUG SampleData – after save, coaches: \(coachesAfter.count), users: \(usersAfter.count)")
            print("DEBUG SampleData – user logs: \(usersAfter.map { $0.username + ": " + "\($0.dailyLogs.count )"})")

        } catch {
            print("DEBUG SampleData – failed to preload: \(error)")
        }
    }
}
