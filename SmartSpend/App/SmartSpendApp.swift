
import SwiftUI
import CoreData
import FirebaseCore

@main
struct SmartSpendApp: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var authManager = AuthManager()
    @StateObject private var faceIDManager = FaceIDManager()

    // Remember if onboarding is completed
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    // Controls the splash screen
    @State private var showSplash = true

    // Detects when the app enters the background
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
        _ = NotificationManager.shared
    }

    var body: some Scene {

        WindowGroup {

            Group {

                if showSplash {

                    SplashView()

                } else if !hasCompletedOnboarding {

                    OnboardingView(
                        hasCompletedOnboarding: $hasCompletedOnboarding
                    )

                } else if authManager.isLoading {

                    ProgressView("Loading SmartSpend...")

                } else if authManager.user == nil {

                    LoginView()

                } else if faceIDManager.isEnabled &&
                            !faceIDManager.isUnlocked {

                    // Shows the lock screen when Face ID is enabled
                    lockedView

                } else {

                    ContentView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(faceIDManager)
            .environment(
                \.managedObjectContext,
                persistenceController.container.viewContext
            )
            .task {

                // Displays splash screen for two seconds
                try? await Task.sleep(for: .seconds(2))
                showSplash = false
            }
            .onAppear {

                NotificationManager.shared.requestPermission()
                NotificationManager.shared.checkPermissionStatus()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in

            // Locks SmartSpend when it enters the background
            if newPhase == .background {
                faceIDManager.lock()
            }
        }
    }

    // Locked Screen

    private var lockedView: some View {

        VStack(spacing: 25) {

            Image(systemName: "faceid")
                .font(.system(size: 85))
                .foregroundStyle(.purple)

            Text("SmartSpend Locked")
                .font(.title)
                .fontWeight(.bold)

            Text("Authenticate to access your finances.")
                .foregroundStyle(.secondary)

            Button("Unlock SmartSpend") {

                Task {
                    await faceIDManager.authenticate()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }
}

