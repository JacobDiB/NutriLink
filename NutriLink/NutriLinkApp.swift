//
//  NutriLinkApp.swift
//  NutriLink
//
//  Created by CS3714 on 11/5/25.
//

import SwiftUI
import SwiftData

@main
struct NutriLinkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    UserAccount.self,
                    CoachAccount.self,
                    DailyLog.self
                ])
        }
    }
}
