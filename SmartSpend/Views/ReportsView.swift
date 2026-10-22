import SwiftUI

struct ReportsView: View {

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.purple)

                Text("Spending Reports")
                    .font(.title)
                    .fontWeight(.bold)

                Text("View your spending insights and financial summaries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            }
            .padding()
            .navigationTitle("Reports")
        }
    }
}

#Preview {
    ReportsView()
}
