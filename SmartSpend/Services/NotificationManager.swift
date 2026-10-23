
import Foundation
import UserNotifications

// Notification Manager

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()

        // Show notifications even when SmartSpend is open
        notificationCenter.delegate = self

        // Observe changes to the Budget Alerts setting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(budgetSettingChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    // Budget Alerts Preference

    // Enabled by default unless the user turns it off
    private var budgetAlertsEnabled: Bool {

        if UserDefaults.standard.object(
            forKey: "budgetAlertsEnabled"
        ) == nil {
            return true
        }

        return UserDefaults.standard.bool(
            forKey: "budgetAlertsEnabled"
        )
    }

    // MARK: - Handle Setting Changes

    @objc private func budgetSettingChanged() {

        // Cancel pending budget notifications when disabled
        if !budgetAlertsEnabled {
            cancelPendingBudgetAlerts()
        }
    }

    // Cancel Pending Budget Alerts

    private func cancelPendingBudgetAlerts() {

        notificationCenter.getPendingNotificationRequests { [weak self] requests in

            guard let self = self else {
                return
            }

            let budgetIDs = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("budget-") }

            self.notificationCenter
                .removePendingNotificationRequests(
                    withIdentifiers: budgetIDs
                )

            print("Pending budget alerts cancelled.")
        }
    }

    // Request Notification Permission

    func requestPermission() {

        notificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in

            if let error = error {
                print(
                    "Notification permission error: \(error.localizedDescription)"
                )
                return
            }

            print("Notification permission granted: \(granted)")
        }
    }

    // Check Notification Permission

    func checkPermissionStatus() {

        notificationCenter.getNotificationSettings { settings in

            print(
                "Notification authorization status: \(settings.authorizationStatus.rawValue)"
            )

            print(
                "Alert setting: \(settings.alertSetting.rawValue)"
            )

            print(
                "Sound setting: \(settings.soundSetting.rawValue)"
            )
        }
    }

    // Check Monthly Budget Alert

    func checkBudgetAlert(
        category: String,
        spent: Double,
        limit: Double,
        month: Date
    ) {

        // Respect the user's Profile setting
        guard budgetAlertsEnabled else {
            print("Budget alerts are disabled.")
            return
        }

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

        // Avoid repeatedly sending the same monthly alert
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

        notificationCenter.add(request) { [weak self] error in

            if let error = error {

                print(
                    "Budget alert error: \(error.localizedDescription)"
                )

            } else {

                // Check again in case the user disabled alerts
                guard let self = self else {
                    return
                }

                if self.budgetAlertsEnabled {

                    UserDefaults.standard.set(
                        newLevel,
                        forKey: alertKey
                    )

                    print(
                        "Budget alert scheduled: \(category) - \(newLevel)%"
                    )

                } else {

                    self.notificationCenter
                        .removePendingNotificationRequests(
                            withIdentifiers: [request.identifier]
                        )
                }
            }
        }
    }

    // Show Notifications While App Is Open

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        // Suppress budget alerts if the user disabled them
        if notification.request.identifier.hasPrefix("budget-"),
           !budgetAlertsEnabled {

            completionHandler([])
            return
        }

        print("Foreground notification received.")

        completionHandler([.banner, .sound, .list])
    }
}

