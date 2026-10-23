
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// Manages user registration, login and logout
@MainActor
class AuthManager: ObservableObject {

    // Stores the currently logged in user
    @Published var user: User?

    // Shows Firebase error messages
    @Published var errorMessage = ""

    // Checks whether Firebase has finished loading
    @Published var isLoading = true

    // Listens for login and logout changes
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {

        // Check if a user is already logged in
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, currentUser in

            Task { @MainActor in
                self?.user = currentUser
                self?.isLoading = false
            }
        }
    }

    // Registers a new user
    func register(name: String, email: String, password: String) async -> Bool {

        errorMessage = ""

        do {
            // Creates an account using Firebase Authentication
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )

            // Save user's name in Firebase Authentication
            let profile = result.user.createProfileChangeRequest()
            profile.displayName = name
            try await profile.commitChanges()

            // Save user's details in Firestore
            try await Firestore.firestore()
                .collection("users")
                .document(result.user.uid)
                .setData([
                    "name": name,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ])

            return true

        } catch {
            // Show an error if registration fails
            errorMessage = error.localizedDescription
            return false
        }
    }

    // Log in an existing user
    func login(email: String, password: String) async -> Bool {

        errorMessage = ""

        do {
            // Check email and password with Firebase
            try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // Log out the current user
    func logout() {

        errorMessage = ""

        do {
            try Auth.auth().signOut()

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

