import SwiftUI

struct ContentView: View {

    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ExpensesView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Expenses")
                }

            BudgetView()
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("Budget")
                }

            ReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(.purple)
    }
}

#Preview {
    ContentView()
}
