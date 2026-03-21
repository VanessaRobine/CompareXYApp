//
//  OnboardingView.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/16/26.
//

import Foundation
import SwiftUI

// MARK: - User Profile Storage
extension UserDefaults {
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let userProfileKey = "userProfile"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    static var userProfile: UserProfile? {
        get {
            guard let data = UserDefaults.standard.data(forKey: userProfileKey),
                  let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
            else { return nil }
            return profile
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: userProfileKey)
            }
        }
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    var lifeStage: String
    var gender: String
    var shopperType: String
    var comparesMost: String
    var decisionStyle: String
    var brandLoyalty: String

    var profileSummary: String {
        "\(lifeStage) (\(gender.lowercased())), \(shopperType.lowercased()), mainly compares \(comparesMost.lowercased()), decides by \(decisionStyle.lowercased()), \(brandLoyalty.lowercased())."
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var lifeStage = ""
    @State private var gender = ""
    @State private var shopperType = ""
    @State private var comparesMost = ""
    @State private var decisionStyle = ""
    @State private var brandLoyalty = ""
    @State private var animating = false

    let steps: [(title: String, subtitle: String, options: [String], emoji: String)] = [
        (
            title: "What's your life stage?",
            subtitle: "This helps us tailor comparisons to what matters most to you.",
            options: ["Student", "Young professional", "Parent", "Retiree", "Other"],
            emoji: "👤"
        ),
        (
            title: "How do you identify?",
            subtitle: "We'll personalize our language and recommendations for you.",
            options: ["Male", "Female", "Non-binary", "Prefer not to say"],
            emoji: "🌈"
        ),
        (
            title: "How do you shop?",
            subtitle: "We'll weight our recommendations accordingly.",
            options: ["Budget hunter", "Value seeker", "Quality first", "Brand loyal", "Impulse buyer"],
            emoji: "🛍️"
        ),
        (
            title: "What do you compare most?",
            subtitle: "We'll use more relevant categories for your comparisons.",
            options: ["Tech & gadgets", "Cars & transport", "Home & appliances", "Fashion & lifestyle", "Everything"],
            emoji: "🔍"
        ),
        (
            title: "How do you decide?",
            subtitle: "We'll highlight what matters to your decision style.",
            options: ["I read specs", "I read reviews", "I compare prices", "I ask friends", "I trust my gut"],
            emoji: "🧠"
        ),
        (
            title: "How do you feel about brands?",
            subtitle: "This shapes how we present brand comparisons.",
            options: ["Stick to brands I know", "Open to anything", "I actively try new brands"],
            emoji: "⭐"
        )
    ]

    var currentSelection: String {
        switch currentStep {
        case 0: return lifeStage
        case 1: return gender
        case 2: return shopperType
        case 3: return comparesMost
        case 4: return decisionStyle
        case 5: return brandLoyalty
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)

                Spacer()

                // Question
                VStack(spacing: 16) {
                    Image("Compare_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.top, 20)

                    Spacer().frame(height: 16)


                    
                    Text(steps[currentStep].emoji)
                        .font(.system(size: 40))

                    Text(steps[currentStep].title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(steps[currentStep].subtitle)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)

                Spacer()

                // Options
                VStack(spacing: 12) {
                    ForEach(steps[currentStep].options, id: \.self) { option in
                        Button {
                            selectOption(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(currentSelection == option ? Color(red: 0.26, green: 0.78, blue: 0.67) : .white)
                                Spacer()
                                if currentSelection == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(red: 0.26, green: 0.78, blue: 0.67))
                                }
                            }
                            .padding()
                            .background(currentSelection == option ? Color.white : Color.white.opacity(0.15))
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("options-\(currentStep)")

                Spacer()

                // Next / Done button
                Button {
                    handleNext()
                } label: {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(currentSelection.isEmpty ? Color.white.opacity(0.3) : Color.white)
                        .foregroundColor(currentSelection.isEmpty ? Color.white.opacity(0.5) : Color(red: 0.26, green: 0.78, blue: 0.67))
                        .cornerRadius(18)
                }
                .disabled(currentSelection.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    func selectOption(_ option: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch currentStep {
            case 0: lifeStage = option
            case 1: gender = option
            case 2: shopperType = option
            case 3: comparesMost = option
            case 4: decisionStyle = option
            case 5: brandLoyalty = option
            default: break
            }
        }
    }

    func handleNext() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            // Save profile
            let profile = UserProfile(
                lifeStage: lifeStage,
                gender: gender,
                shopperType: shopperType,
                comparesMost: comparesMost,
                decisionStyle: decisionStyle,
                brandLoyalty: brandLoyalty
            )
            UserDefaults.userProfile = profile
            UserDefaults.hasCompletedOnboarding = true
            withAnimation {
                isPresented = false
            }
        }
    }
}
