import SwiftUI

struct ProfileView: View {

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.purple)

                Text("My Profile")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Manage your account and settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
