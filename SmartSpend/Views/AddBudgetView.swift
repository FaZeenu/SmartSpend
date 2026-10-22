
import Foundation

import SwiftUI
import CoreData

struct AddBudgetView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var category = "Food"
    @State private var amount = ""
    @State private var month = Date()

    @State private var showError = false
    @State private var errorMessage = ""

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

                Section("Budget Details") {

                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { item in
                            Text(item)
                        }
                    }

                    TextField("Monthly Budget (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker(
                        "Budget Month",
                        selection: $month,
                        displayedComponents: .date
                    )
                }

                Section {

                    Button("Save Budget") {
                        saveBudget()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Unable to Save Budget", isPresented: $showError) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    private func saveBudget() {

        guard let budgetAmount = Double(amount) else {
            errorMessage = "Please enter a valid budget amount."
            showError = true
            return
        }

        if !budgetAmount.isFinite || budgetAmount <= 0 {
            errorMessage = "Budget amount must be greater than zero."
            showError = true
            return
        }

        let calendar = Calendar.current

        let monthComponents = calendar.dateComponents(
            [.year, .month],
            from: month
        )

        guard let selectedMonth = calendar.date(
            from: monthComponents
        ) else {
            errorMessage = "Please select a valid month."
            showError = true
            return
        }

        let request: NSFetchRequest<Budget> = Budget.fetchRequest()

        request.predicate = NSPredicate(
            format: "category == %@ AND month == %@",
            category,
            selectedMonth as NSDate
        )

        do {

            let existingBudgets = try viewContext.fetch(request)

            if !existingBudgets.isEmpty {
                errorMessage = "A budget already exists for this category and month."
                showError = true
                return
            }

            let newBudget = Budget(context: viewContext)

            newBudget.id = UUID()
            newBudget.category = category
            newBudget.amount = budgetAmount
            newBudget.month = selectedMonth

            try viewContext.save()

            dismiss()

        } catch {

            viewContext.rollback()

            errorMessage = "Could not save the budget. Please try again."
            showError = true

            print("Budget save error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddBudgetView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
