
import SwiftUI
import CoreData

struct BudgetView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Budget.month, ascending: false)
        ],
        animation: .default
    )
    private var budgets: FetchedResults<Budget>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Expense.date, ascending: false)
        ],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    @State private var showAddBudget = false

    private var currentMonthBudgets: [Budget] {

        var results: [Budget] = []

        for budget in budgets {

            if let budgetMonth = budget.month {

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

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Monthly Budgets")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(Date(), format: .dateTime.month(.wide).year())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if currentMonthBudgets.isEmpty {

                        VStack(spacing: 15) {

                            Image(systemName: "chart.pie")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple)

                            Text("No budgets for this month")
                                .font(.headline)

                            Text("Set a monthly budget to start tracking your spending.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button("Add Your First Budget") {
                                showAddBudget = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)

                    } else {

                        ForEach(currentMonthBudgets, id: \.objectID) { budget in

                            budgetCard(budget)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }
        }
    }

    private func budgetCard(_ budget: Budget) -> some View {

        let spent = calculateSpending(
            for: budget.category ?? "Other"
        )

        let remaining = budget.amount - spent

        let progress: Double

        if budget.amount > 0 {
            progress = min(max(spent / budget.amount, 0), 1)
        } else {
            progress = 0
        }

        return VStack(alignment: .leading, spacing: 15) {

            HStack {

                Text(budget.category ?? "Other")
                    .font(.headline)

                Spacer()

                Text("Rs. \(budget.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ProgressView(value: progress)
                .tint(progressColor(spent: spent, limit: budget.amount))

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

            if spent >= budget.amount {

                Label(
                    "Budget limit reached or exceeded",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)

            } else if spent >= budget.amount * 0.8 {

                Label(
                    "You are approaching your budget limit",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func calculateSpending(for category: String) -> Double {

        var total = 0.0

        for expense in expenses {

            if expense.category == category {

                if let expenseDate = expense.date {

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

    private func progressColor(spent: Double, limit: Double) -> Color {

        if spent >= limit {
            return .red

        } else if spent >= limit * 0.8 {
            return .orange

        } else {
            return .green
        }
    }
}

#Preview {
    BudgetView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

