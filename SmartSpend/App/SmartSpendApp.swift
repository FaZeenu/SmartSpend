import SwiftUI
import CoreData

@main
struct SmartSpendApp: App {

    let persistenceController = PersistenceController.shared

    init() {
        // Initialize the notification manager
        // and register its delegate.
        _ = NotificationManager.shared
    }

    var body: some Scene {

        WindowGroup {

            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
                .onAppear {

                    NotificationManager.shared.requestPermission()

                    NotificationManager.shared.checkPermissionStatus()
                }
        }
    }
}
