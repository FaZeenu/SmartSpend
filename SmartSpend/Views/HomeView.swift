
import SwiftUI
import CoreData

// HomeView is the main dashboard of SmartSpend.
struct HomeView: View {

    // MARK: Fetch Expense Records

    // Get all expenses from Core Data.
    // Sort them from newest to oldest.
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

    // MARK: Fetch Income Records

    // Get all income records from Core Data.
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \Income.date,
                ascending: false
            )
        ],
        animation: .default
    )
    private var incomes: FetchedResults<Income>

    // MARK: State Variables

    // Control which screens are displayed.
    @State private var showAddExpense = false
    @State private var showAddIncome = false
    @State private var showIncomeHistory = false
    @State private var showSavingsGoals = false

    // MARK: Calculate Total Income

    // Add together all saved income amounts.
    private var totalIncome: Double {

        var total = 0.0

        for income in incomes {
            total = total + income.amount
        }

        return total
    }

    // MARK: Calculate Total Expenses

    // Add together all saved expense amounts.
    private var totalExpenses: Double {

        var total = 0.0

        for expense in expenses {
            total = total + expense.amount
        }

        return total
    }

    // MARK: Calculate Total Balance

    // Balance = Total Income - Total Expenses
    private var totalBalance: Double {

        return totalIncome - totalExpenses
    }

    // MARK: Main Dashboard

    var body: some View {

        NavigationStack {

            // Allow the dashboard to scroll vertically.
            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Welcome Section

                    HStack {

                        VStack(alignment: .leading, spacing: 5) {

                            Text("Hello, Welcome Back!")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Here's your financial overview")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(.purple)
                    }

                    // MARK: Total Balance Card

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))

                        Text("Rs. \(totalBalance, specifier: "%.2f")")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Your available balance")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(25)
                    .background(Color.purple)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )

                    // MARK: Income and Expense Summary

                    HStack(spacing: 15) {

                        // Income summary card.
                        summaryCard(
                            title: "Income",
                            amount: totalIncome,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )

                        // Expense summary card.
                        summaryCard(
                            title: "Expenses",
                            amount: totalExpenses,
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                    }

                    // MARK: Quick Actions

                    Text("Quick Actions")
                        .font(.headline)

                    HStack(spacing: 15) {

                        // Open Add Expense screen.
                        Button {

                            showAddExpense = true

                        } label: {

                            quickAction(
                                title: "Add Expense",
                                icon: "minus.circle.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        // Open Add Income screen.
                        Button {

                            showAddIncome = true

                        } label: {

                            quickAction(
                                title: "Add Income",
                                icon: "plus.circle.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: Income History

                    Button {

                        showIncomeHistory = true

                    } label: {

                        HStack(spacing: 15) {

                            Image(systemName: "list.bullet.rectangle")
                                .font(.title3)

                            Text("View Income History")
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.purple)
                        .padding()
                        .background(
                            Color(.secondarySystemBackground)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)

                    // MARK: Savings Goals

                    Button {

                        showSavingsGoals = true

                    } label: {

                        HStack(spacing: 15) {

                            Image(systemName: "target")
                                .font(.title3)

                            Text("My Savings Goals")
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(.purple)
                        .padding()
                        .background(
                            Color(.secondarySystemBackground)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)

                    // MARK: Recent Transactions

                    Text("Recent Transactions")
                        .font(.headline)

                    // Display a message if no expenses exist.
                    if expenses.isEmpty {

                        VStack(spacing: 10) {

                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)

                            Text("No expenses yet")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)

                    } else {

                        // Show only the five most recent expenses.
                        VStack(spacing: 15) {

                            ForEach(
                                Array(expenses.prefix(5)),
                                id: \.objectID
                            ) { expense in

                                transactionRow(
                                    title: expense.title ?? "Expense",
                                    amount: expense.amount,
                                    icon: categoryIcon(
                                        for: expense.category ?? "Other"
                                    )
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")

            // MARK: Add Expense Screen

            .sheet(isPresented: $showAddExpense) {

                AddExpenseView()
            }

            // MARK: Add Income Screen

            .sheet(isPresented: $showAddIncome) {

                AddIncomeView()
            }

            // MARK: Income History Screen

            .sheet(isPresented: $showIncomeHistory) {

                IncomeView()
            }

            // MARK: Savings Goals Screen

            .sheet(isPresented: $showSavingsGoals) {

                SavingsGoalsView()
            }
        }
    }

    // MARK: Summary Card

    // Reusable card for displaying income or expenses.
    private func summaryCard(
        title: String,
        amount: Double,
        icon: String,
        color: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Rs. \(amount, specifier: "%.2f")")
                .font(.headline)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
    }

    // MARK: Quick Action Card

    // Reusable design for Add Expense and Add Income.
    private func quickAction(
        title: String,
        icon: String
    ) -> some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.purple)

            Text(title)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
    }

    // MARK: Transaction Row

    // Display one expense in the recent transactions list.
    private func transactionRow(
        title: String,
        amount: Double,
        icon: String
    ) -> some View {

        HStack(spacing: 15) {

            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.1))
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text("- Rs. \(amount, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    // MARK: Expense Category Icons

    // Return a different icon for each expense category.
    private func categoryIcon(for category: String) -> String {

        if category == "Food" {
            return "fork.knife"

        } else if category == "Transport" {
            return "car.fill"

        } else if category == "Shopping" {
            return "bag.fill"

        } else if category == "Education" {
            return "book.fill"

        } else if category == "Bills" {
            return "doc.text.fill"

        } else if category == "Health" {
            return "cross.case.fill"

        } else if category == "Entertainment" {
            return "film.fill"

        } else {
            return "creditcard.fill"
        }
    }
}

// MARK: Xcode Preview

#Preview {

    HomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

