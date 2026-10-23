
import Foundation
import SwiftUI
import CoreData

// This screen displays and manages the user's savings goals.
struct SavingsGoalsView: View {

    // MARK: Core Data

    // Access the Core Data database.
    @Environment(\.managedObjectContext)
    private var viewContext

    // Fetch all savings goals from Core Data.
    // Display the newest goals first.
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \SavingsGoal.createdAt,
                ascending: false
            )
        ],
        animation: .default
    )
    private var goals: FetchedResults<SavingsGoal>

    // MARK: State Variables

    // Controls the Add Savings Goal screen.
    @State private var showAddGoal = false

    // Stores the goal selected for adding savings.
    @State private var selectedGoal: SavingsGoal?

    // Stores the goal selected for deletion.
    @State private var goalToDelete: SavingsGoal?

    // Controls the delete confirmation alert.
    @State private var showDeleteConfirmation = false

    // Controls the error alert.
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: Calculate Total Target

    // Calculate the total target amount of all savings goals.
    private var totalTarget: Double {

        var total = 0.0

        for goal in goals {
            total = total + goal.targetAmount
        }

        return total
    }

    // MARK: Calculate Total Savings

    // Calculate the total amount saved across all goals.
    private var totalSaved: Double {

        var total = 0.0

        for goal in goals {
            total = total + goal.savedAmount
        }

        return total
    }

    // MARK: Main User Interface

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Total Savings Card

                    // Display the total saved amount and total target.
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Total Savings")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))

                        Text("Rs. \(totalSaved, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Target: Rs. \(totalTarget, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
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

                    // MARK: Savings Goals Heading

                    Text("My Savings Goals")
                        .font(.title2)
                        .fontWeight(.bold)

                    // MARK: Empty State

                    // Display a message if no savings goals exist.
                    if goals.isEmpty {

                        VStack(spacing: 15) {

                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple)

                            Text("No savings goals yet")
                                .font(.headline)

                            Text(
                                "Create your first savings goal to start tracking your progress."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                            // Open the Add Savings Goal screen.
                            Button("Create Savings Goal") {

                                showAddGoal = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)

                    } else {

                        // MARK: Savings Goals List

                        // Display each saved goal using a goal card.
                        ForEach(goals, id: \.objectID) { goal in

                            goalCard(goal)
                        }
                    }
                }
                .padding()
            }

            // MARK: Navigation Bar

            .navigationTitle("Savings Goals")

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    // Open the Add Savings Goal screen.
                    Button {

                        showAddGoal = true

                    } label: {

                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
            }

            // MARK: Add Savings Goal Sheet

            .sheet(isPresented: $showAddGoal) {

                AddSavingsGoalView()
            }

            // MARK: Add Savings Contribution Sheet

            // Open the contribution form for the selected goal.
            .sheet(item: $selectedGoal) { goal in

                AddSavingsContributionView(goal: goal)
            }

            // MARK: Delete Confirmation

            .alert(
                "Delete Savings Goal",
                isPresented: $showDeleteConfirmation
            ) {

                Button("Cancel", role: .cancel) {

                    goalToDelete = nil
                }

                Button("Delete", role: .destructive) {

                    deleteSelectedGoal()
                }

            } message: {

                Text(
                    "Are you sure you want to delete this savings goal?"
                )
            }

            // MARK: Error Alert

            .alert(
                "Unable to Delete Savings Goal",
                isPresented: $showError
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    // MARK: Savings Goal Card

    // Create a card to display the details of one savings goal.
    private func goalCard(_ goal: SavingsGoal) -> some View {

        // Calculate how much more money is needed.
        // max prevents the remaining amount from becoming negative.
        let remaining = max(
            goal.targetAmount - goal.savedAmount,
            0
        )

        // Calculate savings progress as a value between 0 and 1.
        let progress: Double

        if goal.targetAmount > 0 {

            progress = min(
                max(goal.savedAmount / goal.targetAmount, 0),
                1
            )

        } else {

            progress = 0
        }

        return VStack(alignment: .leading, spacing: 15) {

            // MARK: Goal Title

            HStack {

                Image(systemName: "target")
                    .foregroundStyle(.purple)

                Text(goal.title ?? "Savings Goal")
                    .font(.headline)

                Spacer()
            }

            // MARK: Saved and Target Amounts

            Text("Rs. \(goal.savedAmount, specifier: "%.2f")")
                .font(.title3)
                .fontWeight(.bold)

            Text("of Rs. \(goal.targetAmount, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // MARK: Progress Bar

            // Show how close the user is to completing the goal.
            ProgressView(value: progress)
                .tint(.purple)

            HStack {

                // Display the percentage saved.
                Text("\(progress * 100, specifier: "%.0f")% saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Display the remaining amount.
                Text("Rs. \(remaining, specifier: "%.2f") remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: Goal Deadline

            // Display the deadline if one was provided.
            if let deadline = goal.deadline {

                Label {

                    Text(deadline, style: .date)

                } icon: {

                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // MARK: Completed Goal Message

            // Show a success message when the goal is completed.
            if goal.targetAmount > 0 &&
                goal.savedAmount >= goal.targetAmount {

                Label(
                    "Savings goal completed!",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)
                .font(.subheadline)
            }

            Divider()

            // MARK: Goal Actions

            HStack(spacing: 20) {

                // Open the Add Savings Contribution screen.
                Button {

                    selectedGoal = goal

                } label: {

                    Label(
                        "Add Savings",
                        systemImage: "plus.circle"
                    )
                    .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)

                // Disable contributions when the goal is completed.
                .disabled(
                    goal.targetAmount <= 0 ||
                    goal.savedAmount >= goal.targetAmount
                )

                Spacer()

                // Ask for confirmation before deleting the goal.
                Button {

                    goalToDelete = goal
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
        .padding()
        .background(
            Color(.secondarySystemBackground)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: Delete Savings Goal

    // Remove the selected savings goal from Core Data.
    private func deleteSelectedGoal() {

        // Check whether a goal was selected.
        guard let goal = goalToDelete else {
            return
        }

        // Mark the selected goal for deletion.
        viewContext.delete(goal)

        do {

            // Save the deletion permanently.
            try viewContext.save()

            // Clear the selected goal.
            goalToDelete = nil

        } catch {

            // Undo unsaved changes if saving fails.
            viewContext.rollback()

            // Display an error message.
            errorMessage = "Could not delete the savings goal. Please try again."
            showError = true

            // Print the error in the Xcode console.
            print(
                "Failed to delete savings goal: \(error.localizedDescription)"
            )

            goalToDelete = nil
        }
    }
}

// MARK: Xcode Preview

#Preview {

    SavingsGoalsView()
        .environment(
            \.managedObjectContext,
            PersistenceController.shared.container.viewContext
        )
}
