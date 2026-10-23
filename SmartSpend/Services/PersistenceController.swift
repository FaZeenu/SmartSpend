
import Foundation
import CoreData

//Core Data Persistence Controller

// This structure manages the Core Data database
// used by the SmartSpend application.
struct PersistenceController {

    // Shared Instance

    // Create one shared PersistenceController
    // that can be accessed throughout the application
    static let shared = PersistenceController()

    // Persistent Container

    // The container manages the Core Data model
    // and the persistent database storage
    let container: NSPersistentContainer

    // Initialization

    // This function runs when the controller is created
    init() {

        // Connect Core Data to the SmartSpendModel data model
        container = NSPersistentContainer(
            name: "SmartSpendModel"
        )

        // Load Database

        // Load the persistent stores used to save data
        container.loadPersistentStores { description, error in

            // Check whether the database failed to load
            if let error = error {

                // Print the error in the Xcode console
                print(
                    "Core Data error: \(error.localizedDescription)"
                )

            } else {

                // Confirm that Core Data loaded successfully
                print("Core Data loaded successfully")
            }
        }

        // Automatically Merge Changes

        // Automatically update the main context
        // when changes are saved by a parent or other context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

