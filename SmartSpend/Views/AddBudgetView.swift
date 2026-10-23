
import Foundation
import SwiftUI
import CoreData

// This screen allows users to create a monthly budget.
struct AddBudgetView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close this screen after saving or cancelling.
    @Environment(\.dismiss)
    private var dismiss

    // Store the values entered by the user.
    @State private var category = "Food"
    @State private var amount = ""
    @State private var month = Date()

    // Control the error alert.
    @State private var showError = false
    @State private var errorMessage = ""

    // Available budget categories.
    private let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Education",
        "Bills",
        "Health",
        "Entertainment",
        "Other"
    ]

    // Defines what appears on the screen.
    var body: some View {

        NavigationStack {

            Form {

                // Section for entering budget details.
                Section("Budget Details") {

                    // Allows the user to select a category.
                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { item in
                            Text(item)
                        }
                    }

                    // Allows the user to enter a budget amount.
                    TextField(
                        "Monthly Budget (Rs.)",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)

                    // Allows the user to select a month.
                    DatePicker(
                        "Budget Month",
                        selection: $month,
                        displayedComponents: .date
                    )
                }

                // Save button.
                Section {

                    Button("Save Budget") {
                        saveBudget()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button at the top.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Show an alert when something goes wrong.
            .alert(
                "Unable to Save Budget",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Save Budget

    // This function validates and saves a new budget.
    private func saveBudget() {

        // Convert the entered amount from text to a number.
        guard let budgetAmount = Double(amount) else {

            errorMessage = "Please enter a valid budget amount."
            showError = true
            return
        }

        // Make sure the amount is a valid positive number.
        if !budgetAmount.isFinite || budgetAmount <= 0 {

            errorMessage = "Budget amount must be greater than zero."
            showError = true
            return
        }

        // Get the current calendar.
        let calendar = Calendar.current

        // Extract only the year and month.
        // For example, 23 October 2026 becomes October 2026.
        let monthComponents = calendar.dateComponents(
            [.year, .month],
            from: month
        )

        // Convert the selected month into a Date value.
        guard let selectedMonth = calendar.date(
            from: monthComponents
        ) else {

            errorMessage = "Please select a valid month."
            showError = true
            return
        }

        // Create a request to search existing budgets.
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()

        // Search for a budget with the same category and month.
        request.predicate = NSPredicate(
            format: "category == %@ AND month == %@",
            category,
            selectedMonth as NSDate
        )

        do {

            // Fetch matching budgets from Core Data.
            let existingBudgets = try viewContext.fetch(request)

            // Prevent duplicate budgets.
            if !existingBudgets.isEmpty {

                errorMessage = "A budget already exists for this category and month."
                showError = true
                return
            }

            // Create a new Budget object.
            let newBudget = Budget(context: viewContext)

            // Assign values to the new budget.
            newBudget.id = UUID()
            newBudget.category = category
            newBudget.amount = budgetAmount
            newBudget.month = selectedMonth

            // Save the budget permanently.
            try viewContext.save()

            // Close the screen after successful saving.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not save the budget. Please try again."
            showError = true

            print(
                "Budget save error: \(error.localizedDescription)"
            )
        }
    }
}

// Allows Xcode to display a preview of this screen.
#Preview {

    AddBudgetView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
