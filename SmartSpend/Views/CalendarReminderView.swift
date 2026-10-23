import SwiftUI

// Allows users to schedule financial reminders.
struct CalendarReminderView: View {

    @State private var title = ""
    @State private var reminderDate = Date()
    @State private var notes = ""

    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let calendarManager = CalendarManager()

    var body: some View {

        NavigationStack {

            Form {

                Section("Reminder Details") {

                    TextField(
                        "Reminder Title",
                        text: $title
                    )

                    DatePicker(
                        "Date and Time",
                        selection: $reminderDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField(
                        "Notes (Optional)",
                        text: $notes
                    )
                }

                Section("Suggestions") {

                    Button("Monthly Budget Review") {
                        title = "Review Monthly Budget"
                    }

                    Button("Bill Payment") {
                        title = "Pay Monthly Bill"
                    }

                    Button("Savings Goal Check") {
                        title = "Review Savings Goal"
                    }
                }

                Section {

                    Button {

                        saveReminder()

                    } label: {

                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add to Calendar")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(
                        isSaving ||
                        title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                    .foregroundStyle(.purple)
                }
            }
            .navigationTitle("Calendar Reminders")
            .navigationBarTitleDisplayMode(.inline)

            .alert(
                "Calendar Reminder",
                isPresented: $showAlert
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(alertMessage)
            }
        }
    }

    // Save Reminder

    private func saveReminder() {

        isSaving = true

        Task {

            do {

                try await calendarManager.addReminder(
                    title: title,
                    date: reminderDate,
                    notes: notes
                )

                alertMessage =
                    "Reminder successfully added to your iPhone Calendar."

            } catch {

                alertMessage = error.localizedDescription
            }

            isSaving = false
            showAlert = true
        }
    }
}

//  Xcode Preview

#Preview {
    CalendarReminderView()
}

