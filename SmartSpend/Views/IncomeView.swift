
import Foundation

import SwiftUI
import CoreData

struct IncomeView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Income.date, ascending: false)
        ],
        animation: .default
    )
    private var incomes: FetchedResults<Income>

    @State private var showAddIncome = false
    @State private var incomeToDelete: Income?
    @State private var showDeleteConfirmation = false

    private var totalIncome: Double {

        var total = 0.0

        for income in incomes {
            total = total + income.amount
        }

        return total
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                VStack(alignment: .leading, spacing: 10) {

                    Text("Total Income")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Rs. \(totalIncome, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)

                if incomes.isEmpty {

                    Spacer()

                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray)

                    Text("No income added yet")
                        .font(.headline)

                    Text("Tap the + button to add your first income")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                } else {

                    List {

                        ForEach(incomes, id: \.objectID) { income in

                            VStack(alignment: .leading, spacing: 12) {

                                HStack(spacing: 15) {

                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)

                                    VStack(alignment: .leading, spacing: 5) {

                                        Text(income.title ?? "Income")
                                            .font(.headline)

                                        Text(income.source ?? "Other")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if let incomeDate = income.date {

                                            Text(incomeDate, style: .date)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text("+ Rs. \(income.amount, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                }

                                Divider()

                                HStack {

                                    Spacer()

                                    Button {

                                        incomeToDelete = income
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
            .navigationTitle("Income History")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showAddIncome = true
                    } label: {

                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }
            .sheet(isPresented: $showAddIncome) {
                AddIncomeView()
            }
            .alert(
                "Delete Income",
                isPresented: $showDeleteConfirmation
            ) {

                Button("Cancel", role: .cancel) {
                    incomeToDelete = nil
                }

                Button("Delete", role: .destructive) {
                    deleteSelectedIncome()
                }

            } message: {

                Text("Are you sure you want to delete this income?")
            }
        }
    }

    private func deleteSelectedIncome() {

        if let income = incomeToDelete {

            viewContext.delete(income)

            do {
                try viewContext.save()
                incomeToDelete = nil

            } catch {

                viewContext.rollback()

                print(
                    "Failed to delete income: \(error.localizedDescription)"
                )
            }
        }
    }
}

#Preview {
    IncomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
