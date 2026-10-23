
import SwiftUI

// This screen displays the user's profile information.
struct ProfileView: View {

    // MARK: User Interface

    var body: some View {

        // Provides navigation for the Profile screen.
        NavigationStack {

            // Arranges all elements vertically.
            VStack(spacing: 20) {

                // Display the profile icon.
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.purple)

                // Display the profile heading.
                Text("My Profile")
                    .font(.title)
                    .fontWeight(.bold)

                // Display a short description.
                Text("Manage your account and settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }
            // Display the screen title in the navigation bar.
            .navigationTitle("Profile")
        }
    }
}

// MARK: Xcode Preview

// Display the Profile screen in Xcode Preview.
#Preview {
    ProfileView()
}
