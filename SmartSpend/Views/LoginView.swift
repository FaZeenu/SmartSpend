
import SwiftUI

struct LoginView: View {

    // Access Firebase authentication
    @EnvironmentObject var authManager: AuthManager

    // Store login details
    @State private var email = ""
    @State private var password = ""

    // Show or hide password
    @State private var showPassword = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Spacer()

                // App title
                Text("SmartSpend")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)

                Text("Welcome back!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Log in to manage your expenses")
                    .foregroundStyle(.gray)

                // Email input
                TextField("Email address", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                // Password input
                Group {

                    if showPassword {

                        TextField("Password", text: $password)
                            .textContentType(.oneTimeCode)

                    } else {

                        SecureField("Password", text: $password)
                            .textContentType(.oneTimeCode)
                    }
                }
                .textFieldStyle(.roundedBorder)

                // Show or hide password
                Toggle("Show password", isOn: $showPassword)
                    .font(.subheadline)

                // Display Firebase errors
                if !authManager.errorMessage.isEmpty {

                    Text(authManager.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Login button
                Button("Log In") {

                    Task {

                        // Sign in using Firebase
                        await authManager.login(
                            email: email,
                            password: password
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                // Open registration screen
                NavigationLink("Don't have an account? Sign Up") {

                    RegisterView()
                }
                .foregroundStyle(.purple)

                Spacer()
            }
            .padding(24)
        }
    }
}

