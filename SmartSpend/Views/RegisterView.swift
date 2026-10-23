
import SwiftUI

struct RegisterView: View {

    // Access Firebase authentication
    @EnvironmentObject var authManager: AuthManager

    // Store registration details
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Display validation errors
    @State private var message = ""

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                Spacer(minLength: 50)

                // App title
                Text("SmartSpend")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)

                Text("Create your account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Start managing your money")
                    .foregroundStyle(.gray)

                // Full name
                TextField("Full name", text: $name)
                    .textFieldStyle(.roundedBorder)

                // Email address
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                // Password input
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.oneTimeCode)

                // Confirm password input
                SecureField("Confirm password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.oneTimeCode)

                // Display validation errors
                if !message.isEmpty {

                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Display Firebase errors
                if !authManager.errorMessage.isEmpty {

                    Text(authManager.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Create account button
                Button("Create Account") {

                    // Check for empty fields
                    if name.isEmpty ||
                       email.isEmpty ||
                       password.isEmpty ||
                       confirmPassword.isEmpty {

                        message = "Please complete all fields."

                    } else if password != confirmPassword {

                        message = "Passwords do not match."

                    } else if password.count < 6 {

                        message = "Password must have at least 6 characters."

                    } else {

                        message = ""

                        Task {

                            // Register using Firebase
                            await authManager.register(
                                name: name,
                                email: email,
                                password: password
                            )
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Spacer()
            }
            .padding(24)
        }
    }
}

