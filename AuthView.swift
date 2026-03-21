//import Foundation
import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo + Title
                VStack(spacing: 16) {
                    Image("Compare_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)

                    Text("Compare")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 12)

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.85))

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Button(action: handleAuth) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.48, green: 0.62, blue: 0.88))
                .foregroundColor(.white)
                .cornerRadius(18)
                .shadow(color: Color(red: 0.48, green: 0.62, blue: 0.88).opacity(0.5), radius: 12, x: 0, y: 6)

                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func handleAuth() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                if isSignUp {
                    try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
                } else {
                    try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
