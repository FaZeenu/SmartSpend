
import Foundation
import UserNotifications

// MARK: - Notification Manager

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private override init() {
        super.init()

        // Allow notifications to be displayed
        // even when SmartSpend is open.
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Request Notification Permission

    func requestPermission() {

        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, error in

                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    return
                }

                print("Notification permission granted: \(granted)")
            }
    }

    // MARK: - Check Notification Permission

    func checkPermissionStatus() {

        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in

                print("Notification authorization status: \(settings.authorizationStatus.rawValue)")
                print("Alert setting: \(settings.alertSetting.rawValue)")
                print("Sound setting: \(settings.soundSetting.rawValue)")
            }
    }

    // MARK: - Check Monthly Budget Alert

    func checkBudgetAlert(
        category: String,
        spent: Double,
        limit: Double,
        month: Date
    ) {

        guard limit > 0 else {
            return
        }

        let percentage = (spent / limit) * 100

        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let monthNumber = calendar.component(.month, from: month)

        let monthKey = String(
            format: "%04d-%02d",
            year,
            monthNumber
        )

        let alertKey = "budgetAlert-\(category)-\(monthKey)"

        let previousLevel = UserDefaults.standard.integer(
            forKey: alertKey
        )

        var newLevel = 0

        if percentage >= 100 {
            newLevel = 100
        } else if percentage >= 80 {
            newLevel = 80
        }

        // Avoid repeatedly sending the same alert.
        guard newLevel > 0,
              newLevel > previousLevel else {

            print("No new budget alert required.")
            return
        }

        let content = UNMutableNotificationContent()

        content.title = "SmartSpend Budget Alert"

        if newLevel == 100 {
            content.body =
                "You have reached or exceeded your \(category) budget limit."
        } else {
            content.body =
                "You have used at least 80% of your \(category) budget."
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "budget-\(category)-\(monthKey)-\(newLevel)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: 5,
                repeats: false
            )
        )

        UNUserNotificationCenter.current().add(request) { error in

            if let error = error {
                print("Budget alert error: \(error.localizedDescription)")
            } else {

                UserDefaults.standard.set(
                    newLevel,
                    forKey: alertKey
                )

                print("Budget alert scheduled: \(category) - \(newLevel)%")
            }
        }
    }

    // MARK: - Show Notifications While App Is Open

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        print("Foreground notification received.")

        completionHandler([.banner, .sound, .list])
    }
}

