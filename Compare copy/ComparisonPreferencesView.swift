//
//  ComparisonPreferencesView.swift
//  Compare
//
//  Created by Vanessa Robine on 3/5/26.
//

import SwiftUI

// MARK: - UserDefaults Keys
extension UserDefaults {
    static let priorityKey = "comp_priority"
    static let budgetKey = "comp_budget"
    static let switchingKey = "comp_switching"

    static var compPriority: String {
        get { UserDefaults.standard.string(forKey: priorityKey) ?? "Balanced" }
        set { UserDefaults.standard.set(newValue, forKey: priorityKey) }
    }
    static var compBudget: String {
        get { UserDefaults.standard.string(forKey: budgetKey) ?? "Moderate" }
        set { UserDefaults.standard.set(newValue, forKey: budgetKey) }
    }
    static var compSwitching: String {
        get { UserDefaults.standard.string(forKey: switchingKey) ?? "New purchase" }
        set { UserDefaults.standard.set(newValue, forKey: switchingKey) }
    }
}

// MARK: - Comparison Preferences View
struct ComparisonPreferencesView: View {
    @Environment(\.dismiss) var dismiss

    @State private var priority: String = UserDefaults.compPriority
    @State private var budget: String = UserDefaults.compBudget
    @State private var switching: String = UserDefaults.compSwitching
    @State private var saved = false
    @State private var resetID = UUID() // forces full redraw on reset

    let priorities = ["Balanced", "Performance", "Value", "Design", "Reliability"]
    let budgets = ["Low", "Moderate", "High", "No limit"]
    let switchingOptions = ["New purchase", "Upgrading", "Replacing", "Just comparing"]

    var body: some View {
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

            VStack(spacing: 0) {

                // Header — fixed at top
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
                    Text("Comparison Preferences")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding()

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        PreferenceCard(title: "Priority", icon: "star.fill") {
                            ForEach(priorities, id: \.self) { option in
                                OptionRow(label: option, isSelected: priority == option) {
                                    priority = option
                                }
                            }
                        }

                        PreferenceCard(title: "Budget", icon: "dollarsign.circle.fill") {
                            ForEach(budgets, id: \.self) { option in
                                OptionRow(label: option, isSelected: budget == option) {
                                    budget = option
                                }
                            }
                        }

                        PreferenceCard(title: "Purchase Context", icon: "arrow.triangle.2.circlepath") {
                            ForEach(switchingOptions, id: \.self) { option in
                                OptionRow(label: option, isSelected: switching == option) {
                                    switching = option
                                }
                            }
                        }

                        // Reset to Defaults
                        Button(action: {
                            priority = "Balanced"
                            budget = "Moderate"
                            switching = "New purchase"
                            saved = false
                            resetID = UUID() // triggers full redraw
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(18)
                        }

                        // Save Button
                        Button(action: {
                            UserDefaults.compPriority = priority
                            UserDefaults.compBudget = budget
                            UserDefaults.compSwitching = switching
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: saved ? "checkmark" : "square.and.arrow.down")
                                Text(saved ? "Saved!" : "Save Preferences")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .background(saved ? Color.green.opacity(0.8) : Color(red: 0.48, green: 0.62, blue: 0.88))
                            .cornerRadius(18)
                            .animation(.easeInOut, value: saved)
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .id(resetID) // re-renders entire scroll content on reset
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

private struct PreferenceCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white.opacity(0.8))

            content
        }
        .padding()
        .cardStyle()
    }
}

private struct OptionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.vertical, 6)
        }
    }
}
