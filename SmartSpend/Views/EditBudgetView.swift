
import Foundation
import SwiftUI
import CoreData

// This screen allows users to edit an existing budget.
struct EditBudgetView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close the Edit Budget screen.
    @Environment(\.dismiss)
    private var dismiss

    // The existing budget selected for editing.
    // @ObservedObject watches for changes to this budget.
    @ObservedObject var budget: Budget

    // Stores the updated amount entered by the user.
    @State private var amount: String

    // Controls error alerts.
    @State private var showError = false
    @State private var errorMessage = ""

    // Initializer

    // Receives the selected budget from BudgetView.
    init(budget: Budget) {

        self.budget = budget

        // Display the existing amount inside the TextField.
        _amount = State(
            initialValue: String(budget.amount)
        )
    }

    // User Interface

    var body: some View {

        NavigationStack {

            Form {

                // Display the existing budget information.
                Section("Budget Details") {

                    // Show the category.
                    // The category cannot be edited on this screen.
                    HStack {

                        Text("Category")

                        Spacer()

                        Text(budget.category ?? "Other")
                            .foregroundStyle(.secondary)
                    }

                    // Show the budget month.
                    // The month cannot be edited on this screen.
                    if let month = budget.month {

                        HStack {

                            Text("Month")

                            Spacer()

                            Text(
                                month,
                                format: .dateTime.month(.wide).year()
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                // Allow the user to update the budget amount.
                Section("Update Budget Limit") {

                    TextField(
                        "Budget Amount (Rs.)",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)
                }

                // Save Changes button.
                Section {

                    Button("Save Changes") {
                        updateBudget()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Display an alert when updating fails.
            .alert(
                "Unable to Update Budget",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // Update Budget

    // This function validates and saves the new budget amount.
    private func updateBudget() {

        // Step 1: Convert the entered amount into a number.
        guard let newAmount = Double(amount) else {

            errorMessage = "Please enter a valid budget amount."
            showError = true
            return
        }

        // Step 2: Check that the amount is positive and valid.
        if !newAmount.isFinite || newAmount <= 0 {

            errorMessage = "Budget amount must be greater than zero."
            showError = true
            return
        }

        // Step 3: Update the existing budget amount.
        budget.amount = newAmount

        // Step 4: Save the updated budget to Core Data.
        do {

            try viewContext.save()

            // Close the screen after saving successfully.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not update the budget."
            showError = true

            // Print the technical error in Xcode.
            print(
                "Budget update error: \(error.localizedDescription)"
            )
        }
    }
}

// Xcode Preview

#Preview {

    let context = PersistenceController.shared.container.viewContext

    // Create a sample budget for the preview.
    let sampleBudget = Budget(context: context)

    sampleBudget.id = UUID()
    sampleBudget.category = "Food"
    sampleBudget.amount = 15000
    sampleBudget.month = Date()

    return EditBudgetView(budget: sampleBudget)
        .environment(\.managedObjectContext, context)
}

