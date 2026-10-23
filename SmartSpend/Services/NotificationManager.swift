
import Foundation
import UserNotifications

// MARK: Notification Manager

// This class manages budget notifications in SmartSpend.
class NotificationManager {

    // MARK: Shared Instance

    // Create one shared NotificationManager
    // that can be accessed throughout the application.
    static let shared = NotificationManager()

    // Prevent other parts of the app from creating
    // additional NotificationManager instances.
    private init() {}

    // MARK: Request Notification Permission

    // Ask the user for permission to display notifications.
    func requestPermission() {

        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, error in

                // Check whether an error occurred.
                if let error = error {

                    print(
                        "Notification permission error: \(error.localizedDescription)"
                    )

                } else {

                    // Print whether the user granted permission.
                    print(
                        "Notification permission granted: \(granted)"
                    )
                }
            }
    }

    // MARK: Check Budget Alert

    // Check whether the user has reached
    // 80% or 100% of a category budget.
    func checkBudgetAlert(
        category: String,
        spent: Double,
        limit: Double,
        month: Date
    ) {

        // Do not calculate alerts for an invalid budget limit.
        if limit <= 0 {
            return
        }

        // MARK: Calculate Budget Percentage

        // Calculate how much of the budget has been used.
        let percentage = (spent / limit) * 100

        // MARK: Create Month Identifier

        // Use the year and month to identify the budget period.
        // Example: October 2026 becomes "2026-10".
        let calendar = Calendar.current

        let year = calendar.component(.year, from: month)
        let monthNumber = calendar.component(.month, from: month)

        let monthKey = String(
            format: "%04d-%02d",
            year,
            monthNumber
        )

        // Create a unique key for this category and month.
        let alertKey = "budgetAlert-\(category)-\(monthKey)"

        // MARK: Check Previous Notification

        // Read the highest alert level previously scheduled.
        // If no value exists, UserDefaults returns 0.
        let previousLevel = UserDefaults.standard.integer(
            forKey: alertKey
        )

        // Store the new alert level.
        var newLevel = 0

        // MARK: Determine Alert Level

        // Check whether the budget has reached 100%.
        if percentage >= 100 {

            newLevel = 100

        } else if percentage >= 80 {

            // Check whether the budget has reached 80%.
            newLevel = 80
        }

        // No notification is required below 80%.
        if newLevel == 0 {
            return
        }

        // Do not repeat the same or a lower alert level.
        if newLevel <= previousLevel {
            return
        }

        // MARK: Create Notification Content

        // Create the notification title and message.
        let content = UNMutableNotificationContent()

        content.title = "SmartSpend Budget Alert"

        // Display a different message for each alert level.
        if newLevel == 100 {

            content.body =
                "You have reached or exceeded your \(category) budget limit."

        } else {

            content.body =
                "You have used at least 80% of your \(category) budget."
        }

        // Play the default notification sound.
        content.sound = .default

        // MARK: Schedule Notification

        // Create a notification request with a unique identifier.
        let request = UNNotificationRequest(
            identifier: "budget-\(category)-\(monthKey)-\(newLevel)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: 2,
                repeats: false
            )
        )

        // Send the request to Apple's notification system.
        UNUserNotificationCenter.current().add(request) { error in

            // Check whether scheduling failed.
            if let error = error {

                print(
                    "Budget notification error: \(error.localizedDescription)"
                )

            } else {

                // Remember the highest scheduled alert level.
                // This prevents duplicate alerts.
                UserDefaults.standard.set(
                    newLevel,
                    forKey: alertKey
                )

                print(
                    "Budget alert scheduled: \(category) - \(newLevel)%"
                )
            }
        }
    }
}

