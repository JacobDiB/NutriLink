//
//  DataModels.swift
//  NutriLink
//
//  Created by Jack Micklus on 11/22/25.
//

import Foundation
import SwiftData

// Stores login info, goals, and coach-related data for a single user
@Model
class UserAccount {

    var email: String
    var password: String
    var username: String
    var dailyLogs: [DailyLog]
    var goalCalories: String
    var goalProtein: String
    var goalCarbs: String
    var goalFat: String
    var mealPlan: String
    var coachNotes: String
    var coach: CoachAccount?

    init(email: String,
         password: String,
         username: String,
         dailyLogs: [DailyLog] = [],
         goalCalories: String,
         goalProtein: String = "",
         goalCarbs: String = "",
         goalFat: String = "",
         mealPlan: String = "",
         coachNotes: String = "",
         coach: CoachAccount? = nil) {
        
        self.email = email
        self.password = password
        self.username = username
        self.dailyLogs = dailyLogs
        self.goalCalories = goalCalories
        self.goalProtein = goalProtein
        self.goalCarbs = goalCarbs
        self.goalFat = goalFat
        self.mealPlan = mealPlan
        self.coachNotes = coachNotes
        self.coach = coach
    }
}

// Represents a nutrition coach and the users they work with
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

// Aggregates calorie and food data for a single day
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

// Individual food item logged by the user, including macros
@Model
class FoodEntry {
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var date: Date

    @Relationship var dailyLog: DailyLog?

    init(name: String,
         calories: Int,
         protein: Double,
         carbs: Double,
         fat: Double,
         date: Date,
         dailyLog: DailyLog? = nil) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
        self.dailyLog = dailyLog
    }
}

