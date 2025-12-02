//
//  DataModels.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/22/25.
//
import Foundation
import SwiftData

@Model
class UserAccount {
    var email: String
    var password: String
    var username: String
    var dailyLogs: [DailyLog]
    var goalCalories: String
    var coach: CoachAccount?

    init(email: String,
         password: String,
         username: String,
         dailyLogs: [DailyLog] = [],
         goalCalories: String,
         coach: CoachAccount? = nil) {
        
        self.email = email
        self.password = password
        self.username = username
        self.dailyLogs = dailyLogs
        self.goalCalories = goalCalories
        self.coach = coach
    }
}

@Model
class CoachAccount {
    var email: String
    var password: String
    var name: String
    var bio: String = ""
    
    @Relationship(deleteRule: .cascade, inverse: \UserAccount.coach)
    var clients: [UserAccount]

    init(email: String,
         password: String,
         name: String,
         clients: [UserAccount] = []) {
        
        self.email = email
        self.password = password
        self.name = name
        self.clients = clients
    }
}

@Model
class DailyLog {
    var date: Date
    var calories: Int

    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.dailyLog)
    var foodEntries: [FoodEntry]

    init(date: Date, calories: Int, foodEntries: [FoodEntry] = []) {
        self.date = date
        self.calories = calories
        self.foodEntries = foodEntries
    }
}

@Model
class FoodEntry {
    var name: String
    var calories: Int
    var date: Date

    @Relationship var dailyLog: DailyLog?

    init(name: String, calories: Int, date: Date, dailyLog: DailyLog? = nil) {
        self.name = name
        self.calories = calories
        self.date = date
        self.dailyLog = dailyLog
    }
}
