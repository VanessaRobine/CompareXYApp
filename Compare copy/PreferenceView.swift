//
//  PreferenceView.swift
//  Compare
//
//  Created by Vanessa Robine on 2/27/26.
//

import SwiftUI


import SwiftUI

struct PreferenceView: View {
    @AppStorage("comp_priority") private var priority = "Performance"
    @AppStorage("comp_budget") private var budget = "Balanced"
    @AppStorage("comp_switching") private var switching = "First Purchase"

    let priorities = ["Camera", "Battery", "Performance", "Price", "Ecosystem"]
    let budgets = ["Premium", "Balanced", "Best Value"]
    let switchingOptions = ["Upgrading", "Switching Brands", "First Purchase"]

    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("What matters most?")
                    .font(.title).bold()
                    .foregroundColor(.white)

                VStack(spacing: 20) {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)

                    Picker("Budget", selection: $budget) {
                        ForEach(budgets, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)

                    Picker("Switching", selection: $switching) {
                        ForEach(switchingOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
