
import SwiftUI
import CoreData

// This screen displays and manages monthly budgets.
struct BudgetView: View {

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Load saved budgets from Core Data.
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \Budget.month,
                ascending: false
            )
        ],
        animation: .default
    )
    private var budgets: FetchedResults<Budget>

    // Load saved expenses to calculate spending.
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

    // Control the Add Budget screen.
    @State private var showAddBudget = false

    // Store the budget selected for editing.
    @State private var selectedBudget: Budget?

    // Store the budget selected for deletion.
    @State private var budgetToDelete: Budget?

    // Control confirmation and error alerts.
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false

    // Current Month Budgets

    // Only display budgets belonging to the current month.
    private var currentMonthBudgets: [Budget] {

        var results: [Budget] = []

        // Go through every saved budget.
        for budget in budgets {

            // Check that the budget has a date.
            if let budgetMonth = budget.month {

                // Check whether the budget belongs to this month.
                if Calendar.current.isDate(
                    budgetMonth,
                    equalTo: Date(),
                    toGranularity: .month
                ) {
                    results.append(budget)
                }
            }
        }

        return results
    }

    // User Interface

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    // Screen heading.
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Monthly Budgets")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Display the current month and year.
                        Text(
                            Date(),
                            format: .dateTime.month(.wide).year()
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    // Show a message when there are no budgets.
                    if currentMonthBudgets.isEmpty {

                        VStack(spacing: 15) {

                            Image(systemName: "chart.pie")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple)

                            Text("No budgets for this month")
                                .font(.headline)

                            Text(
                                "Set a monthly budget to start tracking your spending."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                            // Open the Add Budget screen.
                            Button("Add Your First Budget") {
                                showAddBudget = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)

                    } else {

                        // Display each budget for the current month.
                        ForEach(
                            currentMonthBudgets,
                            id: \.objectID
                        ) { budget in

                            budgetCard(budget)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")

            // Plus button to add a new budget.
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showAddBudget = true
                    } label: {

                        Image(systemName: "plus")
                    }
                }
            }

            // Add Budget Sheet

            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }

            //  Edit Budget Sheet

            .sheet(item: $selectedBudget) { budget in
                EditBudgetView(budget: budget)
            }

            //  Delete Confirmation

            .alert(
                "Delete Budget",
                isPresented: $showDeleteConfirmation
            ) {

                Button("Cancel", role: .cancel) {
                    budgetToDelete = nil
                }

                Button("Delete", role: .destructive) {
                    deleteSelectedBudget()
                }

            } message: {

                Text("Are you sure you want to delete this budget?")
            }

            // Show an alert if deletion fails.
            .alert(
                "Unable to Delete Budget",
                isPresented: $showDeleteError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text("The budget could not be deleted. Please try again.")
            }
        }
    }

    // Budget Card

    // Creates the card displayed for each budget.
    private func budgetCard(_ budget: Budget) -> some View {

        // Find how much the user has spent in this category.
        let spent = calculateSpending(
            for: budget.category ?? "Other"
        )

        // Calculate the remaining budget amount.
        let remaining = budget.amount - spent

        // Calculate progress between 0 and 1.
        let progress: Double

        if budget.amount > 0 {
            progress = min(max(spent / budget.amount, 0), 1)
        } else {
            progress = 0
        }

        return VStack(alignment: .leading, spacing: 15) {

            // Category and budget limit.
            HStack {

                Text(budget.category ?? "Other")
                    .font(.headline)

                Spacer()

                Text("Rs. \(budget.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Show spending progress.
            ProgressView(value: progress)
                .tint(
                    progressColor(
                        spent: spent,
                        limit: budget.amount
                    )
                )

            // Display spent and remaining amounts.
            HStack {

                VStack(alignment: .leading, spacing: 5) {

                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Rs. \(spent, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {

                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Rs. \(remaining, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Show a warning when the budget is exceeded.
            if spent >= budget.amount {

                Label(
                    "Budget limit reached or exceeded",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)

            } else if spent >= budget.amount * 0.8 {

                // Show a warning when spending reaches 80%.
                Label(
                    "You are approaching your budget limit",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }

            Divider()

            // Edit and Delete Buttons

            HStack {

                // Open the Edit Budget screen.
                Button {

                    selectedBudget = budget

                } label: {

                    Label(
                        "Edit",
                        systemImage: "pencil"
                    )
                    .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)

                Spacer()

                // Ask for confirmation before deleting.
                Button {

                    budgetToDelete = budget
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Calculate Monthly Spending

    // Adds expenses from the current month for a category.
    private func calculateSpending(for category: String) -> Double {

        var total = 0.0

        // Go through every saved expense.
        for expense in expenses {

            // Check whether the expense belongs to this category.
            if expense.category == category {

                // Check whether the expense has a date.
                if let expenseDate = expense.date {

                    // Check whether it belongs to the current month.
                    if Calendar.current.isDate(
                        expenseDate,
                        equalTo: Date(),
                        toGranularity: .month
                    ) {
                        total = total + expense.amount
                    }
                }
            }
        }

        return total
    }

    // Budget Progress Color

    // Choose a color based on spending.
    private func progressColor(
        spent: Double,
        limit: Double
    ) -> Color {

        // Red when the budget limit is reached.
        if spent >= limit {
            return .red

        // Orange when at least 80% is spent.
        } else if spent >= limit * 0.8 {
            return .orange

        // Green when spending is below 80%.
        } else {
            return .green
        }
    }

    // Delete Budget

    // Delete the budget selected by the user.
    private func deleteSelectedBudget() {

        // Make sure a budget was selected.
        if let budget = budgetToDelete {

            // Mark the budget for deletion.
            viewContext.delete(budget)

            do {

                // Save the deletion to Core Data.
                try viewContext.save()

                // Clear the selected budget.
                budgetToDelete = nil

            } catch {

                // Undo the deletion if saving fails.
                viewContext.rollback()

                budgetToDelete = nil
                showDeleteError = true

                print(
                    "Budget delete error: \(error.localizedDescription)"
                )
            }
        }
    }
}

//  Xcode Preview

#Preview {

    BudgetView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

