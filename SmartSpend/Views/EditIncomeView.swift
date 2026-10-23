
import Foundation
import SwiftUI
import CoreData

// This screen allows users to edit an existing income.
struct EditIncomeView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close the Edit Income screen.
    @Environment(\.dismiss)
    private var dismiss

    // The income record selected for editing.
    @ObservedObject var income: Income

    // Store the information entered by the user.
    @State private var title: String
    @State private var amount: String
    @State private var source: String
    @State private var date: Date
    @State private var notes: String

    // Control the error alert.
    @State private var showError = false
    @State private var errorMessage = ""

    // Available income sources.
    private let sources = [
        "Allowance",
        "Salary",
        "Part-Time Job",
        "Scholarship",
        "Gift",
        "Other"
    ]

    // Initializer

    // Receive the existing income from IncomeView.
    init(income: Income) {

        self.income = income

        // Load the existing values into the form.
        _title = State(initialValue: income.title ?? "")
        _amount = State(initialValue: String(income.amount))
        _source = State(initialValue: income.source ?? "Other")
        _date = State(initialValue: income.date ?? Date())
        _notes = State(initialValue: income.notes ?? "")
    }

    //  User Interface

    var body: some View {

        NavigationStack {

            Form {

                // Income information section.
                Section("Income Details") {

                    // Edit the income title.
                    TextField("Income Title", text: $title)

                    // Edit the income amount.
                    TextField("Amount (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    // Select an income source.
                    Picker("Income Source", selection: $source) {

                        ForEach(sources, id: \.self) { item in
                            Text(item)
                        }
                    }

                    // Select the income date.
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                }

                // Optional notes section.
                Section("Additional Information") {

                    TextField(
                        "Notes (Optional)",
                        text: $notes
                    )
                }

                // Save button.
                Section {

                    Button("Save Changes") {
                        updateIncome()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }

            // Screen title.
            .navigationTitle("Edit Income")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Display an alert if validation or saving fails.
            .alert(
                "Unable to Update Income",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // Update Income

    // Validate and save changes to the existing income.
    private func updateIncome() {

        // Step 1: Remove unnecessary spaces from the title.
        let incomeTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Check whether the title is empty.
        if incomeTitle.isEmpty {

            errorMessage = "Please enter an income title."
            showError = true
            return
        }

        // Step 2: Convert the amount into a number.
        guard let incomeAmount = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // Step 3: Check that the amount is greater than zero.
        if !incomeAmount.isFinite || incomeAmount <= 0 {

            errorMessage = "Income amount must be greater than zero."
            showError = true
            return
        }

        // Step 4: Update the existing income record.
        income.title = incomeTitle
        income.amount = incomeAmount
        income.source = source
        income.date = date
        income.notes = notes

        // Step 5: Save the changes in Core Data.
        do {

            try viewContext.save()

            // Close the screen after saving.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not update the income. Please try again."
            showError = true

            // Print the error in Xcode for debugging.
            print(
                "Income update error: \(error.localizedDescription)"
            )
        }
    }
}

// Xcode Preview

#Preview {

    // Access the Core Data context.
    let context = PersistenceController.shared.container.viewContext

    // Create a sample income for preview.
    let sampleIncome = Income(context: context)

    sampleIncome.id = UUID()
    sampleIncome.title = "Monthly Allowance"
    sampleIncome.amount = 20000
    sampleIncome.source = "Allowance"
    sampleIncome.date = Date()

    return EditIncomeView(income: sampleIncome)
        .environment(\.managedObjectContext, context)
}

