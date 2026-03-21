import SwiftUI
import Supabase
import Combine

@main
struct CompareApp: App {

    @StateObject private var authManager = AuthManager()
    @State private var showOnboarding = !UserDefaults.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.78, blue: 0.67),
                            Color(red: 0.48, green: 0.62, blue: 0.88)
                        ],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                    .ignoresSafeArea()

                    Text("Compare")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            } else if authManager.isLoggedIn {
                ContentView()
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView(isPresented: $showOnboarding)
                    }
            } else {
                AuthView()
            }
        }
    }
}

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = true

    init() {
        Task {
            for await state in await SupabaseManager.shared.client.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    await MainActor.run {
                        self.isLoggedIn = state.session != nil
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
