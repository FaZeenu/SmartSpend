
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

// Displays the user's profile and app settings.
struct ProfileView: View {

    // Firebase authentication.
    @EnvironmentObject var authManager: AuthManager

    // Face ID authentication.
    @EnvironmentObject var faceIDManager: FaceIDManager

    // Save the user's budget alert preference.
    @AppStorage("budgetAlertsEnabled")
    private var budgetAlertsEnabled = true

    // User information.
    @State private var userName = "SmartSpend User"
    @State private var userEmail = ""

    // Face ID error alert.
    @State private var showFaceIDError = false

    // Notification permission alert.
    @State private var showNotificationError = false

    // Prevent repeated authentication requests.
    @State private var isEnablingFaceID = false

    // User Interface

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 24) {

                    //  Profile Header

                    VStack(spacing: 12) {

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 75))
                            .foregroundStyle(.purple)

                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("SmartSpend Account")
                            .font(.caption)
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )

                    // Security & Notifications

                    VStack(alignment: .leading, spacing: 12) {

                        Text("SECURITY & NOTIFICATIONS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {

                            // Face ID setting.
                            HStack(spacing: 14) {

                                Image(systemName: "faceid")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                                    .frame(width: 30)

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text("Face ID")
                                        .fontWeight(.medium)

                                    Text("Secure app access")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Toggle(
                                    "Face ID",
                                    isOn: Binding(
                                        get: {
                                            faceIDManager.isEnabled
                                        },
                                        set: { enabled in

                                            if enabled {
                                                enableFaceID()
                                            } else {
                                                faceIDManager.isEnabled = false
                                                faceIDManager.lock()
                                            }
                                        }
                                    )
                                )
                                .labelsHidden()
                                .tint(.purple)
                                .disabled(isEnablingFaceID)
                            }
                            .padding()

                            Divider()
                                .padding(.leading, 55)

                            // Budget notification setting.
                            HStack(spacing: 14) {

                                Image(systemName: "bell.badge.fill")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                                    .frame(width: 30)

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text("Budget Alerts")
                                        .fontWeight(.medium)

                                    Text("Notifications at 80% and 100%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Toggle(
                                    "Budget Alerts",
                                    isOn: Binding(
                                        get: {
                                            budgetAlertsEnabled
                                        },
                                        set: { enabled in
                                            updateBudgetAlerts(enabled)
                                        }
                                    )
                                )
                                .labelsHidden()
                                .tint(.purple)
                            }
                            .padding()
                        }
                        .background(
                            Color(.secondarySystemBackground)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    }

                    // Financial Tools

                    VStack(alignment: .leading, spacing: 12) {

                        Text("FINANCIAL TOOLS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        NavigationLink {

                            CalendarReminderView()

                        } label: {

                            HStack(spacing: 14) {

                                Image(
                                    systemName: "calendar.badge.clock"
                                )
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .frame(width: 30)

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text("Calendar Reminders")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text("Bills and budget reviews")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                Color(.secondarySystemBackground)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Sign Out

                    Button {

                        // Disable Face ID for the next login.
                        faceIDManager.isEnabled = false
                        faceIDManager.lock()

                        // Sign out of Firebase.
                        authManager.logout()

                    } label: {

                        Label(
                            "Sign Out",
                            systemImage:
                                "rectangle.portrait.and.arrow.right"
                        )
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Text("SmartSpend")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)

            // Load account information.
            .task {
                await loadUserProfile()
            }

            // Face ID error message.
            .alert(
                "Authentication Unavailable",
                isPresented: $showFaceIDError
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(
                    "Set up Face ID or a device passcode in Settings and try again."
                )
            }

            // Notification permission message.
            .alert(
                "Notifications Disabled",
                isPresented: $showNotificationError
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(
                    "Enable notifications for SmartSpend in your iPhone Settings to receive budget alerts."
                )
            }
        }
    }

    // Load Firebase Profile

    private func loadUserProfile() async {

        guard let user = Auth.auth().currentUser else {
            return
        }

        userEmail = user.email ?? ""

        // First check Firebase Authentication.
        if let displayName = user.displayName,
           !displayName.isEmpty {

            userName = displayName
            return
        }

        // Otherwise load the registered name from Firestore.
        do {

            let document = try await Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .getDocument()

            if let name = document.data()?["name"] as? String,
               !name.isEmpty {

                userName = name
            }

        } catch {

            print(
                "Profile loading error: \(error.localizedDescription)"
            )
        }
    }

    //  Enable Face ID

    private func enableFaceID() {

        guard faceIDManager.isBiometricAvailable() else {
            showFaceIDError = true
            return
        }

        isEnablingFaceID = true

        Task {

            let success = await faceIDManager.authenticate()

            if success {

                faceIDManager.isEnabled = true

                print("Face ID enabled successfully.")

            } else {

                showFaceIDError = true
            }

            isEnablingFaceID = false
        }
    }

    // Update Budget Alerts

    private func updateBudgetAlerts(_ enabled: Bool) {

        if !enabled {

            // Save the disabled preference.
            budgetAlertsEnabled = false

            print("Budget alerts disabled.")

            return
        }

        // Request notification permission when enabling alerts.
        Task {

            let center = UNUserNotificationCenter.current()

            do {

                let granted = try await center.requestAuthorization(
                    options: [.alert, .badge, .sound]
                )

                if granted {

                    budgetAlertsEnabled = true

                    print("Budget alerts enabled.")

                } else {

                    budgetAlertsEnabled = false
                    showNotificationError = true
                }

            } catch {

                budgetAlertsEnabled = false
                showNotificationError = true

                print(
                    "Notification permission error: \(error.localizedDescription)"
                )
            }
        }
    }
}

//  Xcode Preview

#Preview {

    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(FaceIDManager())
}

