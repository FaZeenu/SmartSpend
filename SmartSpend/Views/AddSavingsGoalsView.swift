
import Foundation
import SwiftUI
import CoreData

// This screen allows the user to create a savings goal.
struct AddSavingsGoalView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close this screen.
    @Environment(\.dismiss)
    private var dismiss

    // Store the details entered by the user.
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var savedAmount = "0"
    @State private var deadline = Date()

    // Control error alerts.
    @State private var showError = false
    @State private var errorMessage = ""

    // User Interface

    // Defines the Add Savings Goal screen.
    var body: some View {

        NavigationStack {

            Form {

                // Section for entering savings goal details.
                Section("Savings Goal Details") {

                    // Enter the name of the savings goal.
                    TextField("Goal Name", text: $title)

                    // Enter the total amount the user wants to save.
                    TextField(
                        "Target Amount (Rs.)",
                        text: $targetAmount
                    )
                    .keyboardType(.decimalPad)

                    // Enter the amount already saved.
                    TextField(
                        "Already Saved (Rs.)",
                        text: $savedAmount
                    )
                    .keyboardType(.decimalPad)

                    // Select the deadline for reaching the goal.
                    DatePicker(
                        "Target Deadline",
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }

                // Button to create the savings goal.
                Section {

                    Button("Create Savings Goal") {
                        saveGoal()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("New Savings Goal")
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
                "Unable to Create Goal",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // Save Savings Goal

    // This function checks the details and saves the goal.
    private func saveGoal() {

        // Step 1: Remove unnecessary spaces from the goal name.
        let goalName = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Make sure the goal name is not empty.
        if goalName.isEmpty {

            errorMessage = "Please enter a savings goal name."
            showError = true
            return
        }

        // Step 2: Convert the target amount into a number.
        guard let target = Double(targetAmount) else {

            errorMessage = "Please enter a valid target amount."
            showError = true
            return
        }

        // Step 3: Convert the already saved amount into a number.
        guard let saved = Double(savedAmount) else {

            errorMessage = "Please enter a valid saved amount."
            showError = true
            return
        }

        // Step 4: Check that the target amount is positive.
        if !target.isFinite || target <= 0 {

            errorMessage = "Target amount must be greater than zero."
            showError = true
            return
        }

        // Step 5: Check that the saved amount is not negative.
        if !saved.isFinite || saved < 0 {

            errorMessage = "Saved amount cannot be negative."
            showError = true
            return
        }

        // Step 6: Make sure savings do not exceed the target.
        if saved > target {

            errorMessage = "Saved amount cannot exceed the target amount."
            showError = true
            return
        }

        // Step 7: Check that the deadline is not in the past.
        if Calendar.current.startOfDay(for: deadline) <
            Calendar.current.startOfDay(for: Date()) {

            errorMessage = "Please select today or a future deadline."
            showError = true
            return
        }

        // Step 8: Create a new SavingsGoal in Core Data.
        let newGoal = SavingsGoal(context: viewContext)

        // Assign the entered information.
        newGoal.id = UUID()
        newGoal.title = goalName
        newGoal.targetAmount = target
        newGoal.savedAmount = saved
        newGoal.deadline = deadline
        newGoal.createdAt = Date()

        // Step 9: Save the savings goal.
        do {

            try viewContext.save()

            // Close the screen after saving.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not save your goal. Please try again."
            showError = true

            // Print the error in the Xcode console.
            print(
                "Savings goal error: \(error.localizedDescription)"
            )
        }
    }
}

// Xcode Preview

#Preview {

    AddSavingsGoalView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

