
import Foundation
import LocalAuthentication
import Combine

// Manages biometric authentication for SmartSpend
@MainActor
class FaceIDManager: ObservableObject {

    // Remembers whether Face ID is enabled
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(
                isEnabled,
                forKey: "faceIDEnabled"
            )
        }
    }

    // Tracks whether the app is unlocked
    @Published var isUnlocked = false

    init() {
        isEnabled = UserDefaults.standard.bool(
            forKey: "faceIDEnabled"
        )
    }

    // Checks whether biometric authentication is available
    func isBiometricAvailable() -> Bool {

        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    // Asks the user to authenticate
    func authenticate() async -> Bool {

        let context = LAContext()

        do {

            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock your SmartSpend account"
            )

            if success {
                isUnlocked = true
            }

            return success

        } catch {

            print("Authentication failed: \(error.localizedDescription)")
            return false
        }
    }

    // Locks the app
    func lock() {
        isUnlocked = false
    }
}

