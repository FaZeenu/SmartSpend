
import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

// HomeView is the main dashboard of SmartSpend.
struct HomeView: View {

    // Fetch Expense Records

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

    // Fetch Income Records

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

    //  State Variables

    @State private var showAddExpense = false
    @State private var showAddIncome = false
    @State private var showIncomeHistory = false
    @State private var showSavingsGoals = false

    // Store the logged-in user's first name.
    @State private var userName = ""

    //  Calculate Total Income

    private var totalIncome: Double {

        var total = 0.0

        for income in incomes {
            total += income.amount
        }

        return total
    }

    //  Calculate Total Expenses

    private var totalExpenses: Double {

        var total = 0.0

        for expense in expenses {
            total += expense.amount
        }

        return total
    }

    //  Calculate Total Balance

    private var totalBalance: Double {
        totalIncome - totalExpenses
    }

    // Main Dashboard

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    //  - Welcome Section

                    HStack {

                        VStack(alignment: .leading, spacing: 5) {

                            Text(
                                "Hello, \(userName.isEmpty ? "there" : userName)! "
                            )
                            .font(.title)
                            .fontWeight(.bold)

                            Text(
                                "Welcome back! Here's your financial overview."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(.purple)
                    }

                    // Total Balance Card

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))

                        Text(
                            "Rs. \(totalBalance, specifier: "%.2f")"
                        )
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

                    // Income and Expense Summary

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

                    // Quick Actions

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

                    // Income History

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

                    // Savings Goals

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

                    // Recent Transactions

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

            // Hide the Dashboard navigation heading.
            .toolbar(.hidden, for: .navigationBar)

            // Load the registered user's name.
            .task {
                await loadUserName()
            }

            // Add Expense Screen

            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }

            // dd Income Screen

            .sheet(isPresented: $showAddIncome) {
                AddIncomeView()
            }

            //  Income History Screen

            .sheet(isPresented: $showIncomeHistory) {
                IncomeView()
            }

            // Savings Goals Screen

            .sheet(isPresented: $showSavingsGoals) {
                SavingsGoalsView()
            }
        }
    }

    //  Load User Name from Firebase

    private func loadUserName() async {

        guard let user = Auth.auth().currentUser else {
            userName = ""
            return
        }

        // First try the Firebase Authentication display name.
        let displayName = user.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !displayName.isEmpty {
            userName = firstName(from: displayName)
            return
        }

        // If unavailable, read the name saved during registration.
        do {

            let document = try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .getDocument()

            let registeredName = document.data()?["name"] as? String ?? ""

            if !registeredName.isEmpty {
                userName = firstName(from: registeredName)
            } else {
                userName = "there"
            }

        } catch {

            print(
                "Could not load user name: \(error.localizedDescription)"
            )

            userName = "there"
        }
    }

    // Return only the first part of the user's name.
    private func firstName(from fullName: String) -> String {

        fullName
            .split(separator: " ")
            .first
            .map(String.init) ?? "there"
    }

    // Summary Card

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

    // Quick Action Card

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

    // Transaction Row

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

    // Expense Category Icons

    private func categoryIcon(for category: String) -> String {

        switch category {

        case "Food":
            return "fork.knife"

        case "Transport":
            return "car.fill"

        case "Shopping":
            return "bag.fill"

        case "Education":
            return "book.fill"

        case "Bills":
            return "doc.text.fill"

        case "Health":
            return "cross.case.fill"

        case "Entertainment":
            return "film.fill"

        default:
            return "creditcard.fill"
        }
    }
}

// Xcode Preview

#Preview {

    HomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

