
import Foundation
import SwiftUI
import CoreData

struct AddExpenseView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

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

                    Button("Save Expense") {
                        saveExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveExpense() {

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        guard let expenseAmount = Double(amount) else {
            return
        }

        if expenseAmount <= 0 {
            return
        }

        let newExpense = Expense(context: viewContext)

        newExpense.id = UUID()
        newExpense.title = title
        newExpense.amount = expenseAmount
        newExpense.category = category
        newExpense.date = date
        newExpense.notes = notes

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save expense: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddExpenseView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
