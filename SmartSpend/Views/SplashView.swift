
import SwiftUI

// First screen displayed when SmartSpend opens.
struct SplashView: View {

    var body: some View {

        ZStack {

            // Purple background.
            Color.purple
                .ignoresSafeArea()

            VStack(spacing: 20) {

                // App logo.
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.white)

                // App name.
                Text("SmartSpend")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)

                // App tagline.
                Text("Track Smart. Spend Better.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                ProgressView()
                    .tint(.white)
                    .padding(.top, 25)
            }
        }
    }
}

//  Xcode Preview

#Preview {
    SplashView()
}

