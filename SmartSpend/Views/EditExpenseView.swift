
import Foundation
import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

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

    // Prevent repeated button taps.
    @State private var isSaving = false

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

    //  User Interface

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

                    Button {

                        updateExpense()

                    } label: {

                        if isSaving {

                            ProgressView()
                                .frame(maxWidth: .infinity)

                        } else {

                            Text("Update Expense")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
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
                    .disabled(isSaving)
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

                Button("OK", role: .cancel) {}

            } message: {

                Text(errorMessage)
            }
        }
    }

    // Load Expense Details

    // Fill the form with the existing expense information.
    private func loadExpenseDetails() {

        title = expense.title ?? ""
        amount = String(expense.amount)
        category = expense.category ?? "Food"
        date = expense.date ?? Date()
        notes = expense.notes ?? ""
    }

    // Update Expense

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

        // Step 2: Convert the amount into a number.
        guard let expenseAmount = Double(amount) else {

            errorMessage = "Please enter a valid amount."
            showError = true
            return
        }

        // Step 3: Check that the amount is positive.
        if !expenseAmount.isFinite || expenseAmount <= 0 {

            errorMessage = "Amount must be greater than zero."
            showError = true
            return
        }

        // Step 4: Check Firebase authentication.
        guard let userId = Auth.auth().currentUser?.uid else {

            errorMessage = "Please log in before updating an expense."
            showError = true
            return
        }

        // Step 5: Get the expense ID.
        guard let expenseId = expense.id else {

            errorMessage = "This expense does not have a valid ID."
            showError = true
            return
        }

        isSaving = true

        // Remember the previous values in case saving fails.
        let oldTitle = expense.title
        let oldAmount = expense.amount
        let oldCategory = expense.category
        let oldDate = expense.date
        let oldNotes = expense.notes

        // Step 6: Update the existing Core Data expense.
        expense.title = expenseTitle
        expense.amount = expenseAmount
        expense.category = category
        expense.date = date
        expense.notes = notes

        do {

            // Step 7: Save changes to Core Data.
            try viewContext.save()

            print("Expense updated in Core Data successfully.")

            // Step 8: Check the budget after updating.
            checkBudgetAfterUpdating()

            // Step 9: Update the same expense in Firebase.
            Task {

                await updateExpenseInFirebase(
                    userId: userId,
                    expenseId: expenseId,
                    title: expenseTitle,
                    amount: expenseAmount,
                    category: category,
                    date: date,
                    notes: notes
                )

                isSaving = false
            }

        } catch {

            // Undo the unsaved changes.
            viewContext.rollback()

            expense.title = oldTitle
            expense.amount = oldAmount
            expense.category = oldCategory
            expense.date = oldDate
            expense.notes = oldNotes

            isSaving = false

            errorMessage = "Could not update the expense."
            showError = true

            print(
                "Expense update error: \(error.localizedDescription)"
            )
        }
    }

    // Update Expense in Firebase

    private func updateExpenseInFirebase(
        userId: String,
        expenseId: UUID,
        title: String,
        amount: Double,
        category: String,
        date: Date,
        notes: String
    ) async {

        do {

            // Update the expense using its existing UUID.
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("expenses")
                .document(expenseId.uuidString)
                .setData([
                    "title": title,
                    "amount": amount,
                    "category": category,
                    "date": Timestamp(date: date),
                    "notes": notes
                ], merge: true)

            print("Expense updated in Firebase successfully.")

            // Close the screen after saving.
            dismiss()

        } catch {

            print(
                "Firebase update error: \(error.localizedDescription)"
            )

            // Core Data was already updated.
            errorMessage =
                "Expense updated locally, but Firebase updating failed."

            showError = true
        }
    }

    //  Check Budget After Updating

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

        // Search for the budget in the selected month.
        let budgetRequest: NSFetchRequest<Budget> =
            Budget.fetchRequest()

        // Match the entire month, not only one exact date.
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

            // Stop if there is no matching budget.
            guard let budget = matchingBudgets.first else {
                return
            }

            // Find expenses in the same category and month.
            let expenseRequest: NSFetchRequest<Expense> =
                Expense.fetchRequest()

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

            // Check whether a budget warning is needed.
            NotificationManager.shared.checkBudgetAlert(
                category: category,
                spent: totalSpent,
                limit: budget.amount,
                month: selectedMonth
            )

            print("Budget checked after expense update.")

        } catch {

            // Budget errors should not undo the expense update.
            print(
                "Budget checking error: \(error.localizedDescription)"
            )
        }
    }
}

