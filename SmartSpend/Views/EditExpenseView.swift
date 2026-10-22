import Foundation
import SwiftUI
import CoreData

struct EditExpenseView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var expense: Expense

    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var date = Date()
    @State private var notes = ""

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

    var body: some View {

        NavigationStack {

            Form {

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

                Section("Additional Information") {

                    TextField("Notes (Optional)", text: $notes)
                }

                Section {

                    Button("Update Expense") {
                        updateExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExpenseDetails()
            }
        }
    }

    private func loadExpenseDetails() {

        title = expense.title ?? ""
        amount = String(expense.amount)
        category = expense.category ?? "Food"
        date = expense.date ?? Date()
        notes = expense.notes ?? ""
    }

    private func updateExpense() {

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        guard let expenseAmount = Double(amount) else {
            return
        }

        if expenseAmount <= 0 {
            return
        }

        expense.title = title
        expense.amount = expenseAmount
        expense.category = category
        expense.date = date
        expense.notes = notes

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to update expense: \(error.localizedDescription)")
        }
    }
}
