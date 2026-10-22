
import SwiftUI
import CoreData

struct HomeView: View {

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Expense.date, ascending: false)
        ],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Income.date, ascending: false)
        ],
        animation: .default
    )
    private var incomes: FetchedResults<Income>

    @State private var showAddExpense = false
    @State private var showAddIncome = false
    @State private var showIncomeHistory = false

    private var totalIncome: Double {

        var total = 0.0

        for income in incomes {
            total = total + income.amount
        }

        return total
    }

    private var totalExpenses: Double {

        var total = 0.0

        for expense in expenses {
            total = total + expense.amount
        }

        return total
    }

    private var totalBalance: Double {
        return totalIncome - totalExpenses
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(25)
                    .background(Color.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    HStack(spacing: 15) {

                        summaryCard(
                            title: "Income",
                            amount: totalIncome,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )

                        summaryCard(
                            title: "Expenses",
                            amount: totalExpenses,
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                    }

                    Text("Quick Actions")
                        .font(.headline)

                    HStack(spacing: 15) {

                        Button {
                            showAddExpense = true
                        } label: {

                            quickAction(
                                title: "Add Expense",
                                icon: "minus.circle.fill"
                            )
                        }
                        .buttonStyle(.plain)

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

                    // Income History Button

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
                        .background(Color(.secondarySystemBackground))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Recent Transactions")
                        .font(.headline)

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
            .sheet(isPresented: $showAddExpense) {

                AddExpenseView()
            }
            .sheet(isPresented: $showAddIncome) {

                AddIncomeView()
            }
            .sheet(isPresented: $showIncomeHistory) {

                IncomeView()
            }
        }
    }

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

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
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

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
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text("- Rs. \(amount, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

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

#Preview {
    HomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

