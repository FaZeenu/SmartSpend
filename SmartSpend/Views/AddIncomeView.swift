
import Foundation
import SwiftUI
import CoreData

// This screen allows users to add income to SmartSpend.
struct AddIncomeView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Allows us to close this screen.
    @Environment(\.dismiss)
    private var dismiss

    // Store the values entered by the user.
    @State private var title = ""
    @State private var amount = ""
    @State private var source = "Allowance"
    @State private var date = Date()
    @State private var notes = ""

    // Control error alerts.
    @State private var showError = false
    @State private var errorMessage = ""

    // Income sources available to the user.
    private let sources = [
        "Allowance",
        "Salary",
        "Part-Time Job",
        "Scholarship",
        "Gift",
        "Other"
    ]

    //User Interface

    // Defines what appears on the Add Income screen.
    var body: some View {

        NavigationStack {

            Form {

                // Section for entering income information.
                Section("Income Details") {

                    // Enter the income title.
                    TextField("Income Title", text: $title)

                    // Enter the income amount.
                    TextField("Amount (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    // Select where the income came from.
                    Picker("Income Source", selection: $source) {

                        ForEach(sources, id: \.self) { item in
                            Text(item)
                        }
                    }

                    // Select the date the income was received.
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                }

                // Optional additional information.
                Section("Additional Information") {

                    TextField(
                        "Notes (Optional)",
                        text: $notes
                    )
                }

                // Save Income button.
                Section {

                    Button("Save Income") {
                        saveIncome()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button at the top of the screen.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Display an alert if validation or saving fails.
            .alert(
                "Unable to Save Income",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // Save Income

    // This function validates the details and saves the income.
    private func saveIncome() {

        // Step 1: Check whether the title is empty.
        if title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {

            errorMessage = "Please enter an income title."
            showError = true
            return
        }

        // Step 2: Convert the entered amount into a Double.
        guard let incomeAmount = Double(amount) else {

            errorMessage = "Please enter a valid income amount."
            showError = true
            return
        }

        // Step 3: Make sure the amount is positive and finite.
        if !incomeAmount.isFinite || incomeAmount <= 0 {

            errorMessage = "Income amount must be greater than zero."
            showError = true
            return
        }

        // Step 4: Create a new Income object in Core Data.
        let newIncome = Income(context: viewContext)

        // Step 5: Assign the user's details to the new object.
        newIncome.id = UUID()
        newIncome.title = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        newIncome.amount = incomeAmount
        newIncome.source = source
        newIncome.date = date
        newIncome.notes = notes

        // Step 6: Save the new income.
        do {

            try viewContext.save()

            // Close the screen after successful saving.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            // Show an error message.
            errorMessage = "Could not save the income. Please try again."
            showError = true

            // Print the technical error in Xcode.
            print(
                "Income save error: \(error.localizedDescription)"
            )
        }
    }
}

// Xcode Preview

// Displays this screen in the Xcode preview.
#Preview {

    AddIncomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

