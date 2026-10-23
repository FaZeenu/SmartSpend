
import Foundation
import SwiftUI
import CoreData

// This screen allows users to add money to a savings goal.
struct AddSavingsContributionView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Allows us to close the screen.
    @Environment(\.dismiss)
    private var dismiss

    // The savings goal selected by the user.
    // @ObservedObject updates the screen when the goal changes.
    @ObservedObject var goal: SavingsGoal

    // Stores the contribution amount entered by the user.
    @State private var amount = ""

    // Controls error messages.
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: User Interface

    var body: some View {

        NavigationStack {

            Form {

                // Display the selected savings goal.
                Section("Savings Goal") {

                    Text(goal.title ?? "Savings Goal")
                        .font(.headline)

                    // Show how much the user has already saved.
                    HStack {

                        Text("Current Savings")

                        Spacer()

                        Text("Rs. \(goal.savedAmount, specifier: "%.2f")")
                    }

                    // Show the total amount the user wants to save.
                    HStack {

                        Text("Target Amount")

                        Spacer()

                        Text("Rs. \(goal.targetAmount, specifier: "%.2f")")
                    }

                    // Show the amount still needed.
                    HStack {

                        Text("Remaining Amount")

                        Spacer()

                        Text(
                            "Rs. \(max(goal.targetAmount - goal.savedAmount, 0), specifier: "%.2f")"
                        )
                        .foregroundStyle(.purple)
                    }
                }

                // User enters the amount they want to add.
                Section("Add Contribution") {

                    TextField(
                        "Amount to Add (Rs.)",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)
                }

                // Button to save the contribution.
                Section {

                    Button("Save Contribution") {
                        saveContribution()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Savings")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button closes the screen.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Display an alert when an error occurs.
            .alert(
                "Unable to Add Savings",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Save Contribution

    // This function checks and saves the entered contribution.
    private func saveContribution() {

        // Step 1: Convert the entered text into a number.
        guard let contribution = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // Step 2: Check that the contribution is positive.
        if !contribution.isFinite || contribution <= 0 {

            errorMessage = "Contribution must be greater than zero."
            showError = true
            return
        }

        // Step 3: Calculate the new savings amount.
        let newSavedAmount = goal.savedAmount + contribution

        // Step 4: Make sure the new total is valid.
        if !newSavedAmount.isFinite {

            errorMessage = "The savings amount is too large."
            showError = true
            return
        }

        // Step 5: Prevent saving more than the target.
        if newSavedAmount > goal.targetAmount {

            errorMessage = "Contribution exceeds the remaining target amount."
            showError = true
            return
        }

        // Step 6: Update the saved amount in Core Data.
        goal.savedAmount = newSavedAmount

        do {

            // Step 7: Save the updated savings goal.
            try viewContext.save()

            // Close the screen after saving.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not save your contribution."
            showError = true

            // Print the technical error in Xcode.
            print(
                "Savings contribution error: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: Xcode Preview

#Preview {

    let context = PersistenceController.shared.container.viewContext

    // Create a sample goal for the preview.
    let sampleGoal = SavingsGoal(context: context)

    sampleGoal.id = UUID()
    sampleGoal.title = "New Laptop"
    sampleGoal.targetAmount = 150000
    sampleGoal.savedAmount = 30000
    sampleGoal.deadline = Date()
    sampleGoal.createdAt = Date()

    return AddSavingsContributionView(goal: sampleGoal)
        .environment(\.managedObjectContext, context)
}

