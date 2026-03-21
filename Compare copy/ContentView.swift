import SwiftUI
import UIKit
import Combine
import Supabase
import Charts

private let accentBlue = Color(red: 0.05, green: 0.20, blue: 0.65)
private let minCharacters = 2

// =======================================================
// NORMALIZE WINNER
// =======================================================

func normalizeWinner(_ winner: String, machineA: String, machineB: String) -> String {
    let w = winner.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if w == "A" || w.hasPrefix(machineA.uppercased()) { return machineA }
    if w == "B" || w.hasPrefix(machineB.uppercased()) { return machineB }
    return "Tie"
}

// =======================================================
// CARD COMPONENT
// =======================================================

struct Card<Content: View>: View {
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

// =======================================================
// SCALES LOGO
// =======================================================

struct ScalesLogoView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("Compare_Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)

            Text("CompareXY")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Before Deciding")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

// =======================================================
// PREFERENCES INDICATOR
// =======================================================

struct PreferencesIndicator: View {
    let priority: String
    let budget: String
    let switching: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption2)
                Text("Active preferences")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                PrefPill(icon: "star.fill", text: priority)
                PrefPill(icon: "dollarsign.circle.fill", text: budget)
                PrefPill(icon: "arrow.triangle.2.circlepath", text: switching)
            }
        }
    }
}

private struct PrefPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .cardStyle()
    }
}

// =======================================================
// WIN CHART
// =======================================================

struct WinChartView: View {
    let machineA: String
    let machineB: String
    let categories: [Category]

    var winsA: Int { categories.filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == machineA }.count }
    var winsB: Int { categories.filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == machineB }.count }
    var ties: Int { categories.filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == "Tie" }.count }

    var body: some View {
        Card {
            Text("Quick Summary")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            Chart {
                BarMark(x: .value("Product", machineA), y: .value("Wins", winsA))
                    .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.7))
                    .cornerRadius(8)
                BarMark(x: .value("Product", machineB), y: .value("Wins", winsB))
                    .foregroundStyle(Color(red: 0.9, green: 0.2, blue: 0.5))
                    .cornerRadius(8)
                if ties > 0 {
                    BarMark(x: .value("Product", "Tie"), y: .value("Wins", ties))
                        .foregroundStyle(Color(red: 0.6, green: 0.0, blue: 0.4))
                        .cornerRadius(8)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(dash: [4]))
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }

            HStack {
                Label("\(machineA): \(winsA) wins", systemImage: "circle.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.7))
                Spacer()
                Label("\(machineB): \(winsB) wins", systemImage: "circle.fill")
                    .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.5))
            }
            .font(.caption)
        }
    }
}

// =======================================================
// CONTENT VIEW
// =======================================================

struct ContentView: View {
    
    @StateObject private var usageManager = UsageManager()
    
    @State private var machineA = ""
    @State private var machineB = ""
    
    @State private var showCameraA = false
    @State private var capturedImageA: UIImage?
    
    @State private var showCameraB = false
    @State private var capturedImageB: UIImage?
    
    @State private var priority = UserDefaults.compPriority
    @State private var budget = UserDefaults.compBudget
    @State private var switching = UserDefaults.compSwitching
    
    // Autocomplete suggestions
    @State private var suggestionsA: [String] = []
    @State private var suggestionsB: [String] = []
    
    @State private var showSuggestionsA = false
    @State private var showSuggestionsB = false
    
    @State private var navigateToResult = false
    @State private var lastTrending: [String] = []
    @State private var isSelectingSuggestion = false
    
    // Trending comparisons
    @State private var trendingComparisons: [(String, String)] = []
    
    let minCharacters = 2
    
    let builtInTrending: [(String, String)] = [
        ("iPhone 15", "Samsung S24"),
        ("Tesla Model 3", "BMW i4")
    ]
    
    let comparisonPool: [(String, String)] = [
        ("iPhone 15", "Samsung S24"),
        ("Tesla Model 3", "BMW i4"),
        ("ChatGPT", "Claude"),
        ("MacBook Air", "Dell XPS"),
        ("Dyson V15", "Shark Stratos"),
        ("Sony A7 IV", "Canon R6"),
        ("Steam Deck", "Nintendo Switch"),
        ("AirPods Pro", "Sony XM5"),
        ("Rolex Submariner", "Omega Seamaster"),
        ("LG WM400HWA", "Samsung WF45T6000AW")
    ]
    
    struct Comparison: Codable {
        let product_a: String
        let product_b: String
    }
    
    var isValid: Bool {
        machineA.trimmingCharacters(in: .whitespacesAndNewlines).count >= minCharacters &&
        machineB.trimmingCharacters(in: .whitespacesAndNewlines).count >= minCharacters
    }
    
    var validationMessage: String? {
        let a = machineA.trimmingCharacters(in: .whitespaces)
        let b = machineB.trimmingCharacters(in: .whitespaces)
        
        if !a.isEmpty && a.count < minCharacters {
            return "First product name is too short"
        }
        if !b.isEmpty && b.count < minCharacters {
            return "Second product name is too short"
        }
        return nil
    }
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                LinearGradient.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // SETTINGS
                    HStack {
                        Spacer()
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(10)
                                .background(Color.white.opacity(0.25))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 32)
                    
                    Spacer()
                    
                    ScalesLogoView()
                        .padding(.bottom, 10)
                    
                    // INPUT
                    VStack(spacing: 16) {
                        
                        // Field A
                        ZStack(alignment: .topLeading) {
                            HStack {
                                TextField("Enter first product", text: $machineA)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(14)
                                    .onChange(of: machineA) { value in
                                        if !isSelectingSuggestion {
                                            loadProductSuggestions(value, forField: "A")
                                        }
                                    }
                                if !machineA.isEmpty {
                                        Button {
                                            machineA = ""
                                            suggestionsA = []
                                            showSuggestionsA = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.7))
                                                .font(.title3)
                                        }
                                    }
                                Button {
                                    showCameraA = true
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.25))
                                        .clipShape(Circle())
                                }
                            }
                            
                            if showSuggestionsA {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(suggestionsA, id: \.self) { suggestion in
                                        Button {
                                            isSelectingSuggestion = true
                                            machineA = suggestion
                                            showSuggestionsA = false
                                            suggestionsA = []
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isSelectingSuggestion = false
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.5))
                                                Text(suggestion)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                        if suggestion != suggestionsA.last {
                                            Divider().background(Color.white.opacity(0.2))
                                        }
                                    }
                                }
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.26, green: 0.78, blue: 0.67), Color(red: 0.48, green: 0.62, blue: 0.88)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .offset(y: 58)
                                .zIndex(1)
                            }
                            }
                            .zIndex(showSuggestionsA ? 2 : 0)

                            // Field B
                            ZStack(alignment: .topLeading) {
                                HStack {
                                    TextField("Enter second product", text: $machineB)
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .onChange(of: machineB) { value in
                                            if !isSelectingSuggestion {
                                                loadProductSuggestions(value, forField: "B")
                                            }
                                        }
                                    if !machineB.isEmpty {
                                            Button {
                                                machineB = ""
                                                suggestionsB = []
                                                showSuggestionsB = false
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .font(.title3)
                                            }
                                        }
                                    Button {
                                        showCameraB = true
                                    } label: {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.25))
                                            .clipShape(Circle())
                                    }
                                }
                                
                                if showSuggestionsB {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(suggestionsB, id: \.self) { suggestion in
                                            Button {
                                                isSelectingSuggestion = true
                                                machineB = suggestion
                                                showSuggestionsB = false
                                                suggestionsB = []
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    isSelectingSuggestion = false
                                                }
                                            } label: {
                                                HStack {
                                                    Image(systemName: "magnifyingglass")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.5))
                                                    Text(suggestion)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                            }
                                            if suggestion != suggestionsB.last {
                                                Divider().background(Color.white.opacity(0.2))
                                            }
                                        }
                                    }
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.26, green: 0.78, blue: 0.67), Color(red: 0.48, green: 0.62, blue: 0.88)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .offset(y: 58)
                                    .zIndex(1)
                                }
                            }
                            .zIndex(showSuggestionsB ? 2 : 0)
                        
                        // TRENDING
                        VStack(alignment: .leading, spacing: 12) {
                            
                            HStack {
                                Text("🔥 Trending Comparisons")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("Random Fun") {
                                    randomComparison()
                                }
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(trendingComparisons, id: \.0) { pair in
                                        SuggestionChip(a: pair.0, b: pair.1) {
                                            machineA = pair.0
                                            machineB = pair.1
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            
                        }
                        
                        if let message = validationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                        
                    }
                    
                    if let profile = UserDefaults.userProfile {
                        HStack(spacing: 8) {
                            PrefPill(icon: "person.fill", text: profile.lifeStage)
                            PrefPill(icon: "star.fill", text: profile.shopperType)
                            PrefPill(icon: "magnifyingglass", text: profile.comparesMost)
                        }
                    }
                    
                    
                    
                    Button {
                        
                        
                        
                        usageManager.useComparison()
                        
                        navigateToResult = true
                        
                    } label: {
                        
                        Text("Compare Now")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isValid
                                ? Color(red: 0.48, green: 0.62, blue: 0.88)
                                : Color.white.opacity(0.3)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }
                    .disabled(!isValid)
                    .navigationDestination(isPresented: $navigateToResult) {
                        ResultView(
                            machineA: machineA.trimmingCharacters(in: .whitespaces),
                            machineB: machineB.trimmingCharacters(in: .whitespaces)
                        )
                    }
                    
                    Spacer()
                    
                }
                .padding(.horizontal)
                
            }
            .onAppear {
                // Fixed: reset so Compare Now always works after returning
                navigateToResult = false
                
                
                // Load local trending first, then try Supabase
                generateTrending()
                loadTrendingFromSupabase()
            }
            .onChange(of: capturedImageA) { image in
                if let image {
                    Task {
                        let detected = await detectProductFromImage(image)
                        machineA = detected
                    }
                }
            }
            
            .onChange(of: capturedImageB) { image in
                if let image {
                    Task {
                        let detected = await detectProductFromImage(image)
                        machineB = detected
                    }
                }
            }
            .sheet(isPresented: $showCameraA) {
                CameraView(image: $capturedImageA)
            }
            
            .sheet(isPresented: $showCameraB) {
                CameraView(image: $capturedImageB)
            }
            
            
            
           
            
        }
    }
    func loadProductSuggestions(_ text: String, forField: String) {
        print("loadProductSuggestions called: \(text) for \(forField)")
        
        if text.count < 2 {
            if forField == "A" {
                suggestionsA = []
                showSuggestionsA = false
            } else {
                suggestionsB = []
                showSuggestionsB = false
            }
            return
        }
        
        Task {
            do {
                struct ProductSuggestion: Decodable {
                    let model: String
                }

                let suggestions: [ProductSuggestion] = try await SupabaseManager.shared.client
                    .from("product_suggestions")
                    .select("model")
                    .ilike("model", value: "%\(text)%")
                    .limit(8)
                    .execute()
                    .value

                let models = suggestions.map { $0.model }
                
                print("suggestionsA: \(models)")
                
                await MainActor.run {
                    if forField == "A" {
                        suggestionsA = models
                        showSuggestionsA = !models.isEmpty
                    } else {
                        suggestionsB = models
                        showSuggestionsB = !models.isEmpty
                    }
                }
            } catch {
                print("Suggestion error:", error)
            }
        }
    }
    func base64Image(_ image: UIImage) -> String? {

        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        return data.base64EncodedString()

    }

    func detectProductFromImage(_ image: UIImage) async -> String {
        guard let base64 = base64Image(image) else {
            return "Unknown product"
        }

        do {
            // FIXED — pass the actual image base64 to the vision API
            let result = try await AIService.shared.detectProductFromImage(base64: base64)
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Unknown product"
        }
    

        let prompt = """
        A user took a photo of a consumer product.

        Identify the product brand and model.

        Return ONLY the product name.

        Examples:
        Dyson V15 Detect
        Sony WH-1000XM5
        BMW i4
        AirPods Pro (2nd generation)
        """

        do {

            let result = try await AIService.shared.simplePrompt(prompt)

            return result
                .trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {

            return "Unknown product"

        }
    }
}


struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

private struct SuggestionChip: View {
    let a: String
    let b: String
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            Text("\(a) vs \(b)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.18))
                )
        }
    }
}

private extension ContentView {
    
    func randomComparison() {
        if let pair = comparisonPool.randomElement() {
            machineA = pair.0
            machineB = pair.1
        }
    }
    
    func generateFallbackTrending() {
        
        let comparisonPool: [(String, String)] = [
            ("ChatGPT","Claude"),
            ("Gemini","ChatGPT"),
            ("MacBook Air","Surface Laptop"),
            ("Dyson V15","Shark Stratos"),
            ("Sony A7 IV","Canon R6"),
            ("Steam Deck","Nintendo Switch"),
            ("AirPods Pro","Sony XM5"),
            ("Tesla Model 3","BMW i4"),
            ("Rolex Submariner","Omega Seamaster"),
            ("iPhone 15","Samsung S24")
        ]
        
        trendingComparisons = comparisonPool
            .shuffled()
            .prefix(6)
            .map { $0 }
    }
    
    func generateTrending() {
        
        // Show local trending immediately
        generateFallbackTrending()
        
        // Then try to fetch AI trending
        Task {
            
            do {
                
                let previous = trendingComparisons
                    .map { "\($0.0)|\($0.1)" }
                    .joined(separator: ", ")
                
                // REPLACE WITH:
                let profileContext: String
                if let profile = UserDefaults.userProfile {
                    profileContext = "User profile: \(profile.profileSummary)"
                } else {
                    profileContext = "General consumer."
                }
                
                let prompt = """
                Give 10 trending product comparisons for this specific user.
                
                \(profileContext)
                
                Tailor the comparisons to their life stage, what they compare most, and their decision style.
                
                Avoid repeating these comparisons:
                \(previous)
                
                Format strictly as:
                productA|productB
                
                Example:
                iPhone 15|Samsung S24
                ChatGPT|Claude
                
                Return only 6 lines. No extra text.
                """
                
                let result = try await AIService.shared.simplePrompt(prompt)
                
                let pairs = result
                    .split(separator: "\n")
                    .compactMap { line -> (String,String)? in
                        
                        let parts = line.split(separator: "|")
                        
                        if parts.count == 2 {
                            return (String(parts[0]), String(parts[1]))
                        }
                        
                        return nil
                    }
                
                if !pairs.isEmpty {
                    
                    await MainActor.run {
                        trendingComparisons = pairs
                    }
                    
                }
                
            } catch {
                
                print("AI trending failed:", error)
                
            }
            
        }
        
    }
    
    
    func loadTrendingFromSupabase() {
        Task {
            do {
                let response = try await SupabaseManager.shared.client
                    .from("Comparisons")
                    .select()
                    .limit(5)
                    .execute()
                
                let rows = response.value as? [[String: Any]] ?? []
                
                let fetched = rows.compactMap { row -> (String, String)? in
                    if let a = row["product_a"] as? String,
                       let b = row["product_b"] as? String {
                        return (a, b)
                    }
                    return nil
                }
                
                // Only replace if we got results
                if !fetched.isEmpty {
                    await MainActor.run {
                        trendingComparisons = fetched
                    }
                }
            } catch {
                print("Supabase fetch error:", error)
                // Falls back to generateTrending() results silently
            }
        }
    }
}
            
               
