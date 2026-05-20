//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Shyngys on 20.05.2026.
//

import SwiftUI
import CoreData

@main
struct WeatherAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
