
import SwiftUI
import CoreData
import Charts

// This screen displays monthly financial reports.
struct ReportsView: View {

    // MARK: Fetch Expenses

    // Retrieve all saved expenses from Core Data.
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

    // MARK: Fetch Income

    // Retrieve all saved income records from Core Data.
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

    // Store the month selected by the user.
    // The current date is selected by default.
    @State private var selectedMonth = Date()

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

    // MARK: Calculate Monthly Income

    // Calculate income recorded during the selected month.
    private var monthlyIncome: Double {

        var total = 0.0

        // Go through all saved income records.
        for income in incomes {

            // Check whether the income has a date.
            if let incomeDate = income.date {

                // Check whether it belongs to the selected month.
                if Calendar.current.isDate(
                    incomeDate,
                    equalTo: selectedMonth,
                    toGranularity: .month
                ) {

                    // Add the income amount.
                    total = total + income.amount
                }
            }
        }

        return total
    }

    // MARK: Calculate Monthly Expenses

    // Calculate expenses recorded during the selected month.
    private var monthlyExpenses: Double {

        var total = 0.0

        // Go through all saved expenses.
        for expense in expenses {

            if let expenseDate = expense.date {

                // Include only expenses from the selected month.
                if Calendar.current.isDate(
                    expenseDate,
                    equalTo: selectedMonth,
                    toGranularity: .month
                ) {

                    total = total + expense.amount
                }
            }
        }

        return total
    }

    // MARK: Calculate Monthly Balance

    // Monthly Balance = Monthly Income - Monthly Expenses
    private var monthlyBalance: Double {

        return monthlyIncome - monthlyExpenses
    }

    // MARK: Calculate Category Spending

    // Calculate how much was spent in each category
    // during the selected month.
    private var categorySpending: [CategorySpending] {

        // Store the category totals.
        var results: [CategorySpending] = []

        // Check each expense category.
        for category in categories {

            var total = 0.0

            // Go through all expenses.
            for expense in expenses {

                // Check whether the expense belongs
                // to the current category.
                if expense.category == category {

                    if let expenseDate = expense.date {

                        // Check whether the expense is
                        // from the selected month.
                        if Calendar.current.isDate(
                            expenseDate,
                            equalTo: selectedMonth,
                            toGranularity: .month
                        ) {

                            total = total + expense.amount
                        }
                    }
                }
            }

            // Only include categories with spending.
            if total > 0 {

                results.append(
                    CategorySpending(
                        category: category,
                        amount: total
                    )
                )
            }
        }

        return results
    }

    // MARK: Main User Interface

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Financial Overview

                    Text("Financial Overview")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Allow the user to select a date.
                    // Reports use the month of the selected date.
                    DatePicker(
                        "Select Month",
                        selection: $selectedMonth,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)

                    // MARK: Monthly Summary

                    VStack(spacing: 15) {

                        // Display total monthly income.
                        reportRow(
                            title: "Total Income",
                            amount: monthlyIncome,
                            color: .green
                        )

                        // Display total monthly expenses.
                        reportRow(
                            title: "Total Expenses",
                            amount: monthlyExpenses,
                            color: .red
                        )

                        // Display the remaining monthly balance.
                        reportRow(
                            title: "Remaining Balance",
                            amount: monthlyBalance,
                            color: .purple
                        )
                    }

                    // MARK: Income vs Expenses Chart

                    Text("Income vs Expenses")
                        .font(.headline)

                    // Create a bar chart comparing
                    // income and expenses.
                    Chart {

                        // Green bar for monthly income.
                        BarMark(
                            x: .value("Type", "Income"),
                            y: .value("Amount", monthlyIncome)
                        )
                        .foregroundStyle(.green)

                        // Red bar for monthly expenses.
                        BarMark(
                            x: .value("Type", "Expenses"),
                            y: .value("Amount", monthlyExpenses)
                        )
                        .foregroundStyle(.red)
                    }
                    .frame(height: 220)
                    .padding()
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 15)
                    )

                    // MARK: Category Spending Chart

                    Text("Spending by Category")
                        .font(.headline)

                    // Show a message when there is no spending.
                    if categorySpending.isEmpty {

                        Text("No expenses recorded for this month.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()

                    } else {

                        // Create a horizontal bar chart
                        // showing spending by category.
                        Chart(categorySpending) { item in

                            BarMark(
                                x: .value(
                                    "Amount",
                                    item.amount
                                ),
                                y: .value(
                                    "Category",
                                    item.category
                                )
                            )
                            .foregroundStyle(.purple)
                        }
                        .frame(height: 300)
                        .padding()
                        .background(
                            Color(.secondarySystemBackground)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Reports")
        }
    }

    // MARK: Reusable Report Row

    // Display a financial label and its amount.
    private func reportRow(
        title: String,
        amount: Double,
        color: Color
    ) -> some View {

        HStack {

            Text(title)
                .font(.subheadline)

            Spacer()

            Text("Rs. \(amount, specifier: "%.2f")")
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding()
        .background(
            Color(.secondarySystemBackground)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: Category Spending Model

// Stores the category name and total spending.
// Identifiable allows SwiftUI Charts to identify each item.
struct CategorySpending: Identifiable {

    let id = UUID()
    let category: String
    let amount: Double
}

// MARK: Xcode Preview

#Preview {

    ReportsView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

