//
//  NutriLinkApp.swift
//  NutriLink
//
//  Created by CS3714 on 11/5/25.
//

import SwiftUI
import SwiftData

// App entry point
@main
struct NutriLinkApp: App {
    var body: some Scene {
        WindowGroup {
            // Root view and persistent data model setup for SwiftData
            ContentView()
                .modelContainer(for: [
                    UserAccount.self,
                    CoachAccount.self,
                    DailyLog.self,
                    FoodEntry.self
                ])
        }
    }
}

