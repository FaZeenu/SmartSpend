
import SwiftUI

// ContentView is the main navigation screen of SmartSpend.
struct ContentView: View {

    // MARK: Main User Interface

    var body: some View {

        // TabView creates the bottom navigation bar.
        TabView {

            // MARK: Home Tab

            // Displays the dashboard with financial summaries.
            HomeView()
                .tabItem {

                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // MARK: Expenses Tab

            // Displays saved expenses and expense management.
            ExpensesView()
                .tabItem {

                    Image(systemName: "creditcard.fill")
                    Text("Expenses")
                }

            // MARK: Budget Tab

            // Displays monthly budgets and spending progress.
            BudgetView()
                .tabItem {

                    Image(systemName: "wallet.pass.fill")
                    Text("Budget")
                }

            // MARK: Reports Tab

            // Displays financial reports and charts.
            ReportsView()
                .tabItem {

                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }

            // MARK: Profile Tab

            // Displays the user's profile and settings.
            ProfileView()
                .tabItem {

                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }

        // Sets the selected tab's accent color to purple.
        .tint(.purple)
    }
}

// MARK: Xcode Preview

// Shows the main navigation screen in Xcode previews.
#Preview {
    ContentView()
}

