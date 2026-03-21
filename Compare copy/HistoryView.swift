//
//  HistoryView.swift
//  Compare
//
//  Created by Vanessa Robine on 3/5/26.
//

import Foundation
import SwiftUI
import Supabase

struct ComparisonRecord: Decodable, Identifiable {
    let id: UUID
    let product_a: String
    let product_b: String
    let result: String?
    let created_at: String
    let user_id: UUID?
    var saved: Bool?
}

// =======================================================
// HISTORY VIEW
// =======================================================

struct HistoryView: View {
    @State private var comparisons: [ComparisonRecord] = []
    @State private var isLoading = true
    @State private var selectedRecord: ComparisonRecord? = nil
    @State private var showSavedOnly = false

    var sortedComparisons: [ComparisonRecord] {
        let filtered = showSavedOnly ? comparisons.filter { $0.saved == true } : comparisons
        return filtered.sorted { $0.created_at > $1.created_at }
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

            } else if comparisons.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.7))
                    Text("No comparisons yet")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Your comparison history will appear here")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Comparison History")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    // Tabs
                    HStack(spacing: 0) {
                        Button {
                            showSavedOnly = false
                        } label: {
                            Text("All")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(showSavedOnly ? .white.opacity(0.5) : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(showSavedOnly ? Color.clear : Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }

                        Button {
                            showSavedOnly = true
                        } label: {
                            Text("Saved ⭐️")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(showSavedOnly ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(showSavedOnly ? Color.white.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    List {
                        ForEach(sortedComparisons) { comparison in
                            Button(action: { selectedRecord = comparison }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("\(comparison.product_a) vs \(comparison.product_b)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button {
                                            Task { await toggleSaved(comparison) }
                                        } label: {
                                            Image(systemName: comparison.saved == true ? "bookmark.fill" : "bookmark")
                                                .foregroundColor(comparison.saved == true ? .yellow : .white.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.4))
                                            .font(.caption)
                                    }
                                    if let result = comparison.result {
                                        Text(result)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(2)
                                    }
                                    Text(formatDate(comparison.created_at))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.white.opacity(0.15))
                            .listRowSeparatorTint(Color.white.opacity(0.15))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await deleteRecord(comparison) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadHistory() }
        .sheet(item: $selectedRecord) { record in
            HistoryDetailView(record: record)
        }
    }

    // MARK: - Data

    private func loadHistory() async {
        do {
            let records: [ComparisonRecord] = try await SupabaseManager.shared.client
                .from("Comparisons")            // ← capital C, matches your table
                .select()
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            comparisons = records
        } catch {
            print("HISTORY ERROR:", error)
        }
        isLoading = false
    }

    private func deleteRecord(_ record: ComparisonRecord) async {
        comparisons.removeAll { $0.id == record.id }
        do {
            try await SupabaseManager.shared.client
                .from("Comparisons")
                .delete()
                .eq("id", value: record.id.uuidString)
                .execute()
            print("DELETE SUCCESS")
        } catch {
            print("DELETE ERROR:", error)
            comparisons.append(record)
        }
    }
    private func toggleSaved(_ record: ComparisonRecord) async {
        let newValue = !(record.saved ?? false)
        if let i = comparisons.firstIndex(where: { $0.id == record.id }) {
            comparisons[i].saved = newValue
        }
        do {
            try await SupabaseManager.shared.client
                .from("Comparisons")
                .update(["saved": newValue])
                .eq("id", value: record.id.uuidString)
                .execute()
        } catch {
            print("SAVE ERROR:", error)
            if let i = comparisons.firstIndex(where: { $0.id == record.id }) {
                comparisons[i].saved = !newValue
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        return dateString
    }
}

// =======================================================
// HISTORY DETAIL VIEW
// =======================================================

struct HistoryDetailView: View {
    @Environment(\.dismiss) var dismiss
    let record: ComparisonRecord

    var body: some View {
        ZStack {
            LinearGradient.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Past Comparison")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("\(record.product_a) vs \(record.product_b)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(formatDate(record.created_at))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if let result = record.result {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(result)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .cardStyle()
                        // Amazon buttons
                        HStack(spacing: 12) {
                            if let urlA = AmazonAffiliate.searchURL(for: record.product_a) {
                                Link(destination: urlA) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "cart.fill")
                                            .font(.caption)
                                        Text(record.product_a)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.9))
                                    .cornerRadius(20)
                                }
                            }
                            
                            if let urlB = AmazonAffiliate.searchURL(for: record.product_b) {
                                Link(destination: urlB) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "cart.fill")
                                            .font(.caption)
                                        Text(record.product_b)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.9))
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Products Compared")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Option A")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(record.product_a)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("vs")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Option B")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(record.product_b)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .cardStyle()

                    Color.clear.frame(height: 40)
                }
                Text("As an Amazon Associate we earn from qualifying purchases")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 8)

                                    Color.clear.frame(height: 40)
                                } // closes VStack
                                .padding()
                                .foregroundColor(.white)
                            } // closes ScrollView
                        }
                    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .long
            display.timeStyle = .short
            return display.string(from: date)
        }
        return dateString
    }

