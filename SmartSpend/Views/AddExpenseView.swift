
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

    // MARK: - User Interface

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

                Button("OK", role: .cancel) {}

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: - Save Expense

    private func saveExpense() {

        // Check that the title is not empty.
        let cleanedTitle = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if cleanedTitle.isEmpty {

            errorMessage = "Please enter an expense title."
            showError = true
            return
        }

        // Convert the entered amount into a number.
        guard let expenseAmount = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // Amount must be positive and finite.
        if !expenseAmount.isFinite || expenseAmount <= 0 {

            errorMessage = "Amount must be greater than zero."
            showError = true
            return
        }

        // Create a new expense in Core Data.
        let newExpense = Expense(context: viewContext)

        // Assign the entered details.
        newExpense.id = UUID()
        newExpense.title = cleanedTitle
        newExpense.amount = expenseAmount
        newExpense.category = category
        newExpense.date = date
        newExpense.notes = notes

        do {

            // Save the expense to the database.
            try viewContext.save()

            print("Expense saved successfully.")

            // Check the monthly budget after saving.
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

    // MARK: - Check Budget After Saving

    private func checkBudgetAfterSaving() {

        let calendar = Calendar.current

        // Find the first day of the expense month.
        guard let selectedMonth = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: date
            )
        ) else {

            print("Could not determine the selected month.")
            return
        }

        // Find the beginning of the following month.
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: selectedMonth
        ) else {

            print("Could not determine the next month.")
            return
        }

        // MARK: Find Matching Budget

        let budgetRequest: NSFetchRequest<Budget> =
            Budget.fetchRequest()

        // Search the entire month rather than one exact date.
        budgetRequest.predicate = NSPredicate(
            format: "category == %@ AND month >= %@ AND month < %@",
            category,
            selectedMonth as NSDate,
            nextMonth as NSDate
        )

        do {

            let matchingBudgets = try viewContext.fetch(
                budgetRequest
            )

            // Debugging information.
            print(
                "Matching budgets found: \(matchingBudgets.count)"
            )

            // Stop if no budget exists for this category/month.
            guard let budget = matchingBudgets.first else {

                print(
                    "No budget found for \(category) in the selected month."
                )
                return
            }

            // MARK: Find Monthly Expenses

            let expenseRequest: NSFetchRequest<Expense> =
                Expense.fetchRequest()

            // Retrieve expenses for the same category and month.
            expenseRequest.predicate = NSPredicate(
                format: "category == %@ AND date >= %@ AND date < %@",
                category,
                selectedMonth as NSDate,
                nextMonth as NSDate
            )

            let monthlyExpenses = try viewContext.fetch(
                expenseRequest
            )

            // Calculate total monthly spending.
            let totalSpent = monthlyExpenses.reduce(0.0) {
                $0 + $1.amount
            }

            // Calculate spending percentage.
            guard budget.amount > 0 else {

                print("Budget amount must be greater than zero.")
                return
            }

            let percentage = (
                totalSpent / budget.amount
            ) * 100

            // MARK: Debugging Information

            print("----- SMARTSPEND BUDGET CHECK -----")
            print("Category: \(category)")
            print("Month: \(selectedMonth)")
            print("Monthly expenses: \(monthlyExpenses.count)")
            print("Total spent: Rs. \(totalSpent)")
            print("Budget limit: Rs. \(budget.amount)")
            print("Budget used: \(percentage)%")
            print("-----------------------------------")

            // MARK: Trigger Budget Notification

            NotificationManager.shared.checkBudgetAlert(
                category: category,
                spent: totalSpent,
                limit: budget.amount,
                month: selectedMonth
            )

            print("Budget alert check completed.")

        } catch {

            // The expense has already been saved.
            // Budget checking errors should not undo it.
            print(
                "Budget checking error: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Xcode Preview

#Preview {

    AddExpenseView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

