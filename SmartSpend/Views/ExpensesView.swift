
import SwiftUI
import CoreData

struct ExpensesView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Expense.date, ascending: false)
        ],
        animation: .default
    )
    private var expenses: FetchedResults<Expense>

    @State private var showAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showDeleteConfirmation = false

    private var totalExpenses: Double {

        var total = 0.0

        for expense in expenses {
            total = total + expense.amount
        }

        return total
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                VStack(alignment: .leading, spacing: 10) {

                    Text("Total Expenses")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Rs. \(totalExpenses, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)

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

                    List {

                        ForEach(expenses, id: \.objectID) { expense in

                            VStack(alignment: .leading, spacing: 12) {

                                HStack(spacing: 15) {

                                    Image(systemName: "creditcard.fill")
                                        .font(.title3)
                                        .foregroundStyle(.purple)

                                    VStack(alignment: .leading, spacing: 5) {

                                        Text(expense.title ?? "Expense")
                                            .font(.headline)

                                        Text(expense.category ?? "Other")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if let expenseDate = expense.date {

                                            Text(expenseDate, style: .date)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text("Rs. \(expense.amount, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.black)
                                }

                                Divider()

                                HStack(spacing: 20) {

                                    Spacer()

                                    Button {
                                        selectedExpense = expense
                                    } label: {

                                        Label("Edit", systemImage: "pencil")
                                            .foregroundStyle(.purple)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        expenseToDelete = expense
                                        showDeleteConfirmation = true
                                    } label: {

                                        Label("Delete", systemImage: "trash")
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
            .navigationTitle("Expenses")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showAddExpense = true
                    } label: {

                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {

                AddExpenseView()
            }
            .sheet(item: $selectedExpense) { expense in

                EditExpenseView(expense: expense)
            }
            .alert("Delete Expense", isPresented: $showDeleteConfirmation) {

                Button("Cancel", role: .cancel) {
                    expenseToDelete = nil
                }

                Button("Delete", role: .destructive) {
                    deleteSelectedExpense()
                }

            } message: {

                Text("Are you sure you want to delete this expense?")
            }
        }
    }

    private func deleteSelectedExpense() {

        if let expense = expenseToDelete {

            viewContext.delete(expense)

            do {
                try viewContext.save()
                expenseToDelete = nil
            } catch {
                viewContext.rollback()
                print("Failed to delete expense: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ExpensesView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

