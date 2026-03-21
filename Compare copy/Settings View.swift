//
//  Settings View.swift
//  Compare
//
//  Created by Vanessa Robine on 3/5/26.
//

import Foundation
import SwiftUI
import Supabase

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var userEmail = ""
    @State private var showOnboarding = false
    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // HEADER
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title2.bold())
                                .padding(10)
                                .background(Color.white.opacity(0.25))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Account Section
                    SettingsCard {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.white)
                            Text(userEmail.isEmpty ? "Loading..." : userEmail)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Preferences Section
                    SettingsCard {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            
                        
                        
                        // Show current profile
                        if let profile = UserDefaults.userProfile {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.white)
                                    Text("Your Profile")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack(spacing: 8) {
                                    ProfilePill(text: profile.lifeStage)
                                    ProfilePill(text: profile.shopperType)
                                }
                                HStack(spacing: 8) {
                                    ProfilePill(text: profile.comparesMost)
                                    ProfilePill(text: profile.decisionStyle)
                                }
                                ProfilePill(text: profile.brandLoyalty)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        Button {
                            UserDefaults.hasCompletedOnboarding = false
                            UserDefaults.userProfile = nil
                            showOnboarding = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.white)
                                Text("Redo Profile Questionnaire")
                                    .foregroundColor(.white)
                                    .pillStyle()
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // History Section
                    SettingsCard {
                        Text("History")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            
                        NavigationLink(destination: HistoryView()) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.white)
                                Text("Comparison History")
                                    .foregroundColor(.white)
                                    .pillStyle()
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Sign Out
                    Button(action: {
                        Task {
                            try? await SupabaseManager.shared.client.auth.signOut()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.48, green: 0.62, blue: 0.88))
                        .cornerRadius(18)
                    }
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .navigationBarHidden(true)
            .task {
                if let user = try? await SupabaseManager.shared.client.auth.user() {
                    userEmail = user.email ?? ""
                }
            }
        }
    }
    
    private struct SettingsCard<Content: View>: View {
        let content: Content
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding()
            .cardStyle()
        }
    }
    private struct ProfilePill: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .cardStyle()
        }
    }
    
}
