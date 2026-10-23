
import Foundation
import EventKit

// Manages SmartSpend calendar reminders
@MainActor
class CalendarManager {

    // Access the iPhone calendar
    private let eventStore = EKEventStore()

    // Request permission to add calendar events
    func requestAccess() async -> Bool {

        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("Calendar permission error: \(error.localizedDescription)")
            return false
        }
    }

    // Add a financial reminder to the calendar
    func addReminder(
        title: String,
        date: Date,
        notes: String
    ) async throws {

        // Request calendar permission
        let allowed = await requestAccess()

        guard allowed else {
            throw NSError(
                domain: "SmartSpendCalendar",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Calendar access was not granted."
                ]
            )
        }

        // Create a calendar event
        let event = EKEvent(eventStore: eventStore)

        event.title = title
        event.startDate = date

        // Reminder lasts 30 minutes
        event.endDate = date.addingTimeInterval(30 * 60)

        event.notes = notes

        // Alert 1 hour before the event
        event.addAlarm(
            EKAlarm(relativeOffset: -60 * 60)
        )

        // Save to the default calendar
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw NSError(
                domain: "SmartSpendCalendar",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No writable calendar is available."
                ]
            )
        }

        event.calendar = calendar

        try eventStore.save(
            event,
            span: .thisEvent
        )
    }
}

