
import SwiftUI
import CoreData

// MARK: Main Application Entry Point

// @main tells Swift that this is where the application starts.
@main
struct SmartSpendApp: App {

    // MARK: Core Data Setup

    // Access the shared PersistenceController.
    // This manages the application's Core Data storage.
    let persistenceController = PersistenceController.shared

    // MARK: Application Scene

    // Define the main window of the application.
    var body: some Scene {

        WindowGroup {

            // MARK: Main Screen

            // ContentView is the first screen loaded.
            // It contains the application's main navigation.
            ContentView()

                // MARK: Connect Core Data

                // Provide the Core Data context to ContentView
                // and its child views.
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )

                // MARK: Notification Permission

                // Runs when ContentView appears.
                .onAppear {

                    // Request permission to display
                    // budget alert notifications.
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}

