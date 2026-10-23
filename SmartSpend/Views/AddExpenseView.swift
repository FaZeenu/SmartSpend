
import Foundation
import SwiftUI
import CoreData

// This screen allows users to add a new expense.
struct AddExpenseView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Used to close the screen.
    @Environment(\.dismiss)
    private var dismiss

    // Store the details entered by the user.
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var date = Date()
    @State private var notes = ""

    // Control error messages.
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

                // Enter expense information.
                Section("Expense Details") {

                    TextField("Expense Title", text: $title)

                    TextField("Amount (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { item in
                            Text(item)
                        }
                    }

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                }

                // Optional expense notes.
                Section("Additional Information") {

                    TextField(
                        "Notes (Optional)",
                        text: $notes
                    )
                }

                // Save expense button.
                Section {

                    Button("Save Expense") {
                        saveExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)

            // Cancel button.
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            // Show an error if validation or saving fails.
            .alert(
                "Unable to Save Expense",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Save Expense

    private func saveExpense() {

        // Check that the title is not empty.
        if title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {

            errorMessage = "Please enter an expense title."
            showError = true
            return
        }

        // Convert the amount from text into a number.
        guard let expenseAmount = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // The amount must be a valid positive number.
        if !expenseAmount.isFinite || expenseAmount <= 0 {

            errorMessage = "Amount must be greater than zero."
            showError = true
            return
        }

        // Create a new expense in Core Data.
        let newExpense = Expense(context: viewContext)

        // Assign the entered details.
        newExpense.id = UUID()
        newExpense.title = title
        newExpense.amount = expenseAmount
        newExpense.category = category
        newExpense.date = date
        newExpense.notes = notes

        do {

            // Save the expense to the database.
            try viewContext.save()

            // Check whether the budget limit has been reached.
            checkBudgetAfterSaving()

            // Close the screen.
            dismiss()

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            errorMessage = "Could not save the expense."
            showError = true

            print(
                "Expense save error: \(error.localizedDescription)"
            )
        }
    }

    // MARK: Check Budget After Saving

    private func checkBudgetAfterSaving() {

        // Find the first day of the selected expense month.
        let calendar = Calendar.current

        let monthComponents = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        guard let selectedMonth = calendar.date(
            from: monthComponents
        ) else {
            return
        }

        // Search for the budget matching the category and month.
        let budgetRequest: NSFetchRequest<Budget> = Budget.fetchRequest()

        budgetRequest.predicate = NSPredicate(
            format: "category == %@ AND month == %@",
            category,
            selectedMonth as NSDate
        )

        do {

            let matchingBudgets = try viewContext.fetch(budgetRequest)

            // If no budget exists, there is nothing to check.
            guard let budget = matchingBudgets.first else {
                return
            }

            // Retrieve expenses belonging to the same category and month.
            let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()

            guard let nextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: selectedMonth
            ) else {
                return
            }

            expenseRequest.predicate = NSPredicate(
                format: "category == %@ AND date >= %@ AND date < %@",
                category,
                selectedMonth as NSDate,
                nextMonth as NSDate
            )

            let monthlyExpenses = try viewContext.fetch(expenseRequest)

            // Calculate total spending for this category.
            var totalSpent = 0.0

            for expense in monthlyExpenses {
                totalSpent = totalSpent + expense.amount
            }

            // Ask NotificationManager to check the budget threshold.
            NotificationManager.shared.checkBudgetAlert(
                category: category,
                spent: totalSpent,
                limit: budget.amount,
                month: selectedMonth
            )

        } catch {

            // The expense is already saved.
            // A notification error should not undo that expense.
            print(
                "Budget checking error: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: Xcode Preview

#Preview {

    AddExpenseView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

