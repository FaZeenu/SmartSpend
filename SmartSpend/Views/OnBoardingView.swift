
import SwiftUI

// This screen introduces SmartSpend to new users.
struct OnboardingView: View {

    // Receives the onboarding completion status from the app.
    @Binding var hasCompletedOnboarding: Bool

    // Tracks the current onboarding page.
    @State private var currentPage = 0

    // Details for the three onboarding screens.
    private let pages: [(icon: String, title: String, description: String)] = [
        (
            "wallet.bifold.fill",
            "Welcome to SmartSpend",
            "Take control of your finances by tracking your income and expenses in one place."
        ),
        (
            "chart.pie.fill",
            "Manage Your Budgets",
            "Set monthly budgets, monitor your spending, and stay on top of your financial goals."
        ),
        (
            "chart.bar.xaxis",
            "Understand Your Spending",
            "View reports, track your progress, and make smarter financial decisions."
        )
    ]

    //  User Interface

    var body: some View {

        VStack(spacing: 20) {

            // Skip onboarding.
            HStack {

                Spacer()

                Button("Skip") {
                    finishOnboarding()
                }
                .foregroundStyle(.purple)
                .padding()
            }

            Spacer()

            // Display the current onboarding page.
            TabView(selection: $currentPage) {

                ForEach(0..<pages.count, id: \.self) { index in

                    VStack(spacing: 25) {

                        // Page illustration.
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 95))
                            .foregroundStyle(.purple)
                            .frame(height: 150)

                        // Page title.
                        Text(pages[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Page description.
                        Text(pages[index].description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 390)

            Spacer()

            // Next or Get Started button.
            Button {

                if currentPage < pages.count - 1 {

                    // Move to the next onboarding screen.
                    withAnimation {
                        currentPage += 1
                    }

                } else {

                    // Finish onboarding and continue to login.
                    finishOnboarding()
                }

            } label: {

                Text(
                    currentPage == pages.count - 1
                    ? "Get Started"
                    : "Next"
                )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    // Finish Onboarding

    private func finishOnboarding() {

        // Save completion so onboarding is not repeated.
        hasCompletedOnboarding = true
    }
}

// Xcode Preview

#Preview {
    OnboardingView(
        hasCompletedOnboarding: .constant(false)
    )
}

