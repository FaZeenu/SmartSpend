
import SwiftUI
import CoreData

// This screen displays and manages all recorded expenses.
struct ExpensesView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // MARK: Fetch Expenses

    // Automatically fetch saved expenses from Core Data.
    // The newest expenses appear first.
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \Expense.date,
                ascending: false
            )
        ],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    // MARK: State Variables

    // Controls the Add Expense screen.
    @State private var showAddExpense = false

    // Stores the expense selected for editing.
    @State private var selectedExpense: Expense?

    // Stores the expense selected for deletion.
    @State private var expenseToDelete: Expense?

    // Controls the delete confirmation alert.
    @State private var showDeleteConfirmation = false

    // Controls error alerts.
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: Calculate Total Expenses

    // Calculate the total amount of all saved expenses.
    private var totalExpenses: Double {

        var total = 0.0

        // Add each expense amount to the total.
        for expense in expenses {
            total = total + expense.amount
        }

        return total
    }

    // MARK: User Interface

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                // MARK: Total Expenses Card

                // Display the total spending amount.
                VStack(alignment: .leading, spacing: 10) {

                    Text("Total Expenses")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Rs. \(totalExpenses, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(20)
                .background(Color.purple)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .padding(.horizontal)

                // MARK: Empty State

                // Show a message when no expenses exist.
                if expenses.isEmpty {

                    Spacer()

                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray)

                    Text("No expenses added yet")
                        .font(.headline)

                    Text("Tap the + button to add your first expense")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                } else {

                    // MARK: Expense List

                    // Display all saved expenses.
                    List {

                        ForEach(expenses, id: \.objectID) { expense in

                            VStack(
                                alignment: .leading,
                                spacing: 12
                            ) {

                                // Display expense information.
                                HStack(spacing: 15) {

                                    Image(systemName: "creditcard.fill")
                                        .font(.title3)
                                        .foregroundStyle(.purple)

                                    VStack(
                                        alignment: .leading,
                                        spacing: 5
                                    ) {

                                        // Expense title.
                                        Text(expense.title ?? "Expense")
                                            .font(.headline)

                                        // Expense category.
                                        Text(expense.category ?? "Other")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        // Expense date.
                                        if let expenseDate = expense.date {

                                            Text(
                                                expenseDate,
                                                style: .date
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // Expense amount.
                                    Text(
                                        "Rs. \(expense.amount, specifier: "%.2f")"
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                }

                                Divider()

                                // MARK: Edit and Delete Buttons

                                HStack(spacing: 20) {

                                    Spacer()

                                    // Open the Edit Expense screen.
                                    Button {

                                        selectedExpense = expense

                                    } label: {

                                        Label(
                                            "Edit",
                                            systemImage: "pencil"
                                        )
                                        .foregroundStyle(.purple)
                                    }
                                    .buttonStyle(.plain)

                                    // Ask for confirmation before deleting.
                                    Button {

                                        expenseToDelete = expense
                                        showDeleteConfirmation = true

                                    } label: {

                                        Label(
                                            "Delete",
                                            systemImage: "trash"
                                        )
                                        .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.subheadline)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }

            // MARK: Navigation Bar

            .navigationTitle("Expenses")

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    // Open the Add Expense screen.
                    Button {

                        showAddExpense = true

                    } label: {

                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }

            // MARK: Add Expense Sheet

            // Display the Add Expense form.
            .sheet(isPresented: $showAddExpense) {

                AddExpenseView()
            }

            // MARK: Edit Expense Sheet

            // Display the Edit Expense form.
            .sheet(item: $selectedExpense) { expense in

                EditExpenseView(expense: expense)
            }

            // MARK: Delete Confirmation

            // Ask the user before deleting an expense.
            .alert(
                "Delete Expense",
                isPresented: $showDeleteConfirmation
            ) {

                Button("Cancel", role: .cancel) {

                    expenseToDelete = nil
                }

                Button("Delete", role: .destructive) {

                    deleteSelectedExpense()
                }

            } message: {

                Text(
                    "Are you sure you want to delete this expense?"
                )
            }

            // MARK: Error Alert

            // Show an error if deleting an expense fails.
            .alert(
                "Unable to Delete Expense",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Delete Expense

    // Remove the selected expense from Core Data.
    private func deleteSelectedExpense() {

        // Check whether an expense was selected.
        guard let expense = expenseToDelete else {
            return
        }

        // Mark the expense for deletion.
        viewContext.delete(expense)

        do {

            // Save the deletion permanently.
            try viewContext.save()

            // Clear the selected expense.
            expenseToDelete = nil

        } catch {

            // Undo the deletion if saving fails.
            viewContext.rollback()

            // Display an error message.
            errorMessage = "Could not delete the expense. Please try again."
            showError = true

            print(
                "Failed to delete expense: \(error.localizedDescription)"
            )

            expenseToDelete = nil
        }
    }
}

// MARK: Xcode Preview

#Preview {

    ExpensesView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

