import SwiftUI
import CoreData

@main
struct SmartSpendApp: App {

    let persistenceController = PersistenceController.shared

    var body: some Scene {

        WindowGroup {

            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}
