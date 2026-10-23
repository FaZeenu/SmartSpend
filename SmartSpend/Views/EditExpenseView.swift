
import Foundation
import SwiftUI
import CoreData

// This screen allows users to edit an existing expense.
struct EditExpenseView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close the Edit Expense screen.
    @Environment(\.dismiss)
    private var dismiss

    // The expense selected for editing.
    @ObservedObject var expense: Expense

    // Store the values displayed in the form.
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var date = Date()
    @State private var notes = ""

    // Control error alerts.
    @State private var showError = false
    @State private var errorMessage = ""

    // Available expense categories.
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

    // MARK: User Interface

    var body: some View {

        NavigationStack {

            Form {

                // Section for editing expense information.
                Section("Expense Details") {

                    TextField("Expense Title", text: $title)

                    TextField("Amount (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    // Select the expense category.
                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { item in
                            Text(item)
                        }
                    }

                    // Change the expense date.
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                }

                // Optional notes.
                Section("Additional Information") {

                    TextField(
                        "Notes (Optional)",
                        text: $notes
                    )
                }

                // Button to save the changes.
                Section {

                    Button("Update Expense") {
                        updateExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Load the original expense information.
            .onAppear {
                loadExpenseDetails()
            }

            // Display validation or saving errors.
            .alert(
                "Unable to Update Expense",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Load Expense Details

    // Fill the form with the existing expense information.
    private func loadExpenseDetails() {

        title = expense.title ?? ""
        amount = String(expense.amount)
        category = expense.category ?? "Food"
        date = expense.date ?? Date()
        notes = expense.notes ?? ""
    }

    // MARK: Update Expense

    // Validate the changes and update the existing expense.
    private func updateExpense() {

        // Step 1: Remove unnecessary spaces from the title.
        let expenseTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Check that the title is not empty.
        if expenseTitle.isEmpty {

            errorMessage = "Please enter an expense title."
            showError = true
            return
        }

        // Step 2: Convert the amount from text to a number.
        guard let expenseAmount = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // Step 3: Check that the amount is positive and valid.
        if !expenseAmount.isFinite || expenseAmount <= 0 {

            errorMessage = "Amount must be greater than zero."
            showError = true
            return
        }

        // Step 4: Update the existing expense information.
        expense.title = expenseTitle
        expense.amount = expenseAmount
        expense.category = category
        expense.date = date
        expense.notes = notes

        do {

            // Step 5: Save the changes to Core Data.
            try viewContext.save()

            // Step 6: Check the budget after updating.
            checkBudgetAfterUpdating()

            // Close the screen.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not update the expense."
            showError = true

            print(
                "Expense update error: \(error.localizedDescription)"
            )
        }
    }

    // MARK: Check Budget After Updating

    // Check whether the updated expense affects a monthly budget.
    private func checkBudgetAfterUpdating() {

        let calendar = Calendar.current

        // Find the first day of the selected expense month.
        let monthComponents = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        guard let selectedMonth = calendar.date(
            from: monthComponents
        ) else {
            return
        }

        // Find the first day of the following month.
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: selectedMonth
        ) else {
            return
        }

        // Search for a budget matching the category and month.
        let budgetRequest: NSFetchRequest<Budget> = Budget.fetchRequest()

        budgetRequest.predicate = NSPredicate(
            format: "category == %@ AND month == %@",
            category,
            selectedMonth as NSDate
        )

        do {

            let matchingBudgets = try viewContext.fetch(budgetRequest)

            // Stop if there is no matching budget.
            guard let budget = matchingBudgets.first else {
                return
            }

            // Find expenses in the same category and month.
            let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()

            expenseRequest.predicate = NSPredicate(
                format: "category == %@ AND date >= %@ AND date < %@",
                category,
                selectedMonth as NSDate,
                nextMonth as NSDate
            )

            let monthlyExpenses = try viewContext.fetch(expenseRequest)

            // Calculate the total spending.
            var totalSpent = 0.0

            for monthlyExpense in monthlyExpenses {
                totalSpent = totalSpent + monthlyExpense.amount
            }

            // Check whether a budget warning should be scheduled.
            NotificationManager.shared.checkBudgetAlert(
                category: category,
                spent: totalSpent,
                limit: budget.amount,
                month: selectedMonth
            )

        } catch {

            // The expense update is already saved.
            // A budget-checking error should not undo it.
            print(
                "Budget checking error: \(error.localizedDescription)"
            )
        }
    }
}
