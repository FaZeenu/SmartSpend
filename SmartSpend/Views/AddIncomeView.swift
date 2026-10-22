
import Foundation

import SwiftUI
import CoreData

struct AddIncomeView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var source = "Allowance"
    @State private var date = Date()
    @State private var notes = ""

    @State private var showError = false

    private let sources = [
        "Allowance",
        "Salary",
        "Part-Time Job",
        "Scholarship",
        "Gift",
        "Other"
    ]

    var body: some View {

        NavigationStack {

            Form {

                Section("Income Details") {

                    TextField("Income Title", text: $title)

                    TextField("Amount (Rs.)", text: $amount)
                        .keyboardType(.decimalPad)

                    Picker("Income Source", selection: $source) {

                        ForEach(sources, id: \.self) { item in
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

                    Button("Save Income") {
                        saveIncome()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .listRowBackground(Color.purple)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Income", isPresented: $showError) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text("Please enter a title and a valid amount greater than zero.")
            }
        }
    }

    private func saveIncome() {

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError = true
            return
        }

        guard let incomeAmount = Double(amount) else {
            showError = true
            return
        }

        if incomeAmount <= 0 {
            showError = true
            return
        }

        let newIncome = Income(context: viewContext)

        newIncome.id = UUID()
        newIncome.title = title
        newIncome.amount = incomeAmount
        newIncome.source = source
        newIncome.date = date
        newIncome.notes = notes

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save income: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddIncomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
