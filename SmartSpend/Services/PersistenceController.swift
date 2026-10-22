import Foundation
import CoreData

struct PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {

        container = NSPersistentContainer(name: "SmartSpendModel")

        container.loadPersistentStores { description, error in

            if let error = error {
                print("Core Data error: \(error.localizedDescription)")
            } else {
                print("Core Data loaded successfully")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
