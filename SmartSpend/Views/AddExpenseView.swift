
import Foundation
import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

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

    // Prevent saving multiple times.
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

    // User Interface

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
                
                
                // MARK: - Receipt Scanning

                Section("Receipt Scanner") {

                    NavigationLink {

                        ReceiptScannerView { receipt in

                            // Automatically fill the expense form.
                            title = receipt.merchant
                            amount = receipt.amount
                            date = receipt.date

                            // Keep recognized receipt text as notes.
                            notes = receipt.notes
                        }

                    } label: {

                        Label(
                            "Scan Receipt with Camera",
                            systemImage: "camera.viewfinder"
                        )
                        .foregroundStyle(.purple)
                    }
                }


                // Save expense button.
                Section {

                    Button {
                        saveExpense()
                    } label: {

                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Expense")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
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

    //  Save Expense

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

        // Make sure a Firebase user is logged in.
        guard let userId = Auth.auth().currentUser?.uid else {

            errorMessage = "Please log in before saving an expense."
            showError = true
            return
        }

        isSaving = true

        // Create a new expense in Core Data
        let newExpense = Expense(context: viewContext)

        // Create one ID for both databases
        let expenseId = UUID()

        // Assign the entered details
        newExpense.id = expenseId
        newExpense.title = cleanedTitle
        newExpense.amount = expenseAmount
        newExpense.category = category
        newExpense.date = date
        newExpense.notes = notes

        do {

            // Save the expense to Core Data
            try viewContext.save()

            print("Expense saved to Core Data successfully.")

            // Check the monthly budget after saving
            checkBudgetAfterSaving()

            // Save a copy to Firebase
            Task {

                await saveExpenseToFirebase(
                    userId: userId,
                    id: expenseId,
                    title: cleanedTitle,
                    amount: expenseAmount,
                    category: category,
                    date: date,
                    notes: notes
                )

                isSaving = false

                // Close the screen after the Firebase attempt
                dismiss()
            }

        } catch {

            // Undo unsaved Core Data changes
            viewContext.rollback()

            isSaving = false
            errorMessage = "Could not save the expense."
            showError = true

            print(
                "Expense save error: \(error.localizedDescription)"
            )
        }
    }

    // Save Expense to Firebase

    private func saveExpenseToFirebase(
        userId: String,
        id: UUID,
        title: String,
        amount: Double,
        category: String,
        date: Date,
        notes: String
    ) async {

        do {

            // Store expenses inside the logged-in user's account.
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("expenses")
                .document(id.uuidString)
                .setData([
                    "title": title,
                    "amount": amount,
                    "category": category,
                    "date": Timestamp(date: date),
                    "notes": notes
                ])

            print("Expense saved to Firebase successfully.")

        } catch {

            // The expense is still saved in Core Data
            print(
                "Firebase expense error: \(error.localizedDescription)"
            )

            // Inform the user that cloud saving failed
            errorMessage = "Expense saved locally, but Firebase saving failed."
            showError = true
        }
    }

    // Check Budget After Saving

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

        // Find Matching Budget

        let budgetRequest: NSFetchRequest<Budget> =
            Budget.fetchRequest()

        // Search for the budget in the selected month
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

            print(
                "Matching budgets found: \(matchingBudgets.count)"
            )

            // Stop if no matching budget exists
            guard let budget = matchingBudgets.first else {

                print(
                    "No budget found for \(category) in the selected month."
                )
                return
            }

            // Find Monthly Expenses

            let expenseRequest: NSFetchRequest<Expense> =
                Expense.fetchRequest()

            // Find expenses for the same category and month
            expenseRequest.predicate = NSPredicate(
                format: "category == %@ AND date >= %@ AND date < %@",
                category,
                selectedMonth as NSDate,
                nextMonth as NSDate
            )

            let monthlyExpenses = try viewContext.fetch(
                expenseRequest
            )

            // Calculate total spending
            let totalSpent = monthlyExpenses.reduce(0.0) {
                $0 + $1.amount
            }

            // Make sure the budget is valid
            guard budget.amount > 0 else {

                print("Budget amount must be greater than zero.")
                return
            }

            // Calculate spending percentage
            let percentage = (
                totalSpent / budget.amount
            ) * 100

            // Debugging Information

            print("----- SMARTSPEND BUDGET CHECK -----")
            print("Category: \(category)")
            print("Month: \(selectedMonth)")
            print("Monthly expenses: \(monthlyExpenses.count)")
            print("Total spent: Rs. \(totalSpent)")
            print("Budget limit: Rs. \(budget.amount)")
            print("Budget used: \(percentage)%")
            print("-----------------------------------")

            //  Trigger Budget Notification

            NotificationManager.shared.checkBudgetAlert(
                category: category,
                spent: totalSpent,
                limit: budget.amount,
                month: selectedMonth
            )

            print("Budget alert check completed.")

        } catch {

            // Budget errors should not undo the saved expense.
            print(
                "Budget checking error: \(error.localizedDescription)"
            )
        }
    }
}

// Xcode Preview

#Preview {

    AddExpenseView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

