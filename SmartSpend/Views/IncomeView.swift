
import SwiftUI
import CoreData

// This screen displays and manages income records.
struct IncomeView: View {

    // MARK: Core Data

    // Access the Core Data database context.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Fetch all income records from Core Data.
    // Display the newest income records first.
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

    // Controls the Add Income screen.
    @State private var showAddIncome = false

    // Stores the income selected for editing.
    @State private var selectedIncome: Income?

    // Stores the income selected for deletion.
    @State private var incomeToDelete: Income?

    // Controls the delete confirmation alert.
    @State private var showDeleteConfirmation = false

    // Controls the error alert.
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: Calculate Total Income

    // Calculate the total amount of all saved income.
    private var totalIncome: Double {

        var total = 0.0

        // Add each income amount to the total.
        for income in incomes {
            total = total + income.amount
        }

        return total
    }

    // MARK: User Interface

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                // MARK: Total Income Card

                // Display the total income amount.
                VStack(alignment: .leading, spacing: 10) {

                    Text("Total Income")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Rs. \(totalIncome, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(20)
                .background(Color.purple)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                .padding(.horizontal)

                // MARK: Empty State

                // Show a message if no income has been added.
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

                    // MARK: Income List

                    // Display all saved income records.
                    List {

                        ForEach(incomes, id: \.objectID) { income in

                            VStack(
                                alignment: .leading,
                                spacing: 12
                            ) {

                                // Display the income information.
                                HStack(spacing: 15) {

                                    Image(
                                        systemName: "arrow.down.circle.fill"
                                    )
                                    .font(.title3)
                                    .foregroundStyle(.green)

                                    VStack(
                                        alignment: .leading,
                                        spacing: 5
                                    ) {

                                        // Income title.
                                        Text(income.title ?? "Income")
                                            .font(.headline)

                                        // Income source.
                                        Text(income.source ?? "Other")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        // Income date.
                                        if let incomeDate = income.date {

                                            Text(incomeDate, style: .date)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    // Income amount.
                                    Text(
                                        "+ Rs. \(income.amount, specifier: "%.2f")"
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                }

                                Divider()

                                // MARK: Edit and Delete Buttons

                                HStack(spacing: 20) {

                                    Spacer()

                                    // Open the Edit Income screen.
                                    Button {

                                        selectedIncome = income

                                    } label: {

                                        Label(
                                            "Edit",
                                            systemImage: "pencil"
                                        )
                                        .foregroundStyle(.purple)
                                    }
                                    .buttonStyle(.plain)

                                    // Ask for confirmation before deleting.
                                    Button {

                                        incomeToDelete = income
                                        showDeleteConfirmation = true

                                    } label: {

                                        Label(
                                            "Delete",
                                            systemImage: "trash"
                                        )
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

            // MARK: Navigation Bar

            .navigationTitle("Income History")

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    // Open the Add Income screen.
                    Button {

                        showAddIncome = true

                    } label: {

                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }

            // MARK: Add Income Screen

            // Show the Add Income form.
            .sheet(isPresented: $showAddIncome) {

                AddIncomeView()
            }

            // MARK: Edit Income Screen

            // Show the Edit Income form.
            .sheet(item: $selectedIncome) { income in

                EditIncomeView(income: income)
            }

            // MARK: Delete Confirmation

            // Ask the user to confirm before deleting income.
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

                Text(
                    "Are you sure you want to delete this income?"
                )
            }

            // MARK: Error Alert

            // Display an error if deletion fails.
            .alert(
                "Unable to Delete Income",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Delete Income

    // Delete the selected income record from Core Data.
    private func deleteSelectedIncome() {

        // Check whether an income record was selected.
        guard let income = incomeToDelete else {
            return
        }

        // Mark the selected income for deletion.
        viewContext.delete(income)

        do {

            // Save the deletion permanently.
            try viewContext.save()

            // Clear the selected income.
            incomeToDelete = nil

        } catch {

            // Undo the deletion if saving fails.
            viewContext.rollback()

            // Display an error message.
            errorMessage = "Could not delete the income. Please try again."
            showError = true

            // Print the error in Xcode.
            print(
                "Failed to delete income: \(error.localizedDescription)"
            )

            incomeToDelete = nil
        }
    }
}

// MARK: Xcode Preview

#Preview {

    IncomeView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}

