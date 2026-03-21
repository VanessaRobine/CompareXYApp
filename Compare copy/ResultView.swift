import SwiftUI
import Supabase
import UIKit

// =======================================================
// LOADING TEXT VIEW
// =======================================================

struct LoadingTextView: View {

    @State private var isVisible = true
    @State private var index = 0

    var messages: [String] {
        [
            "Gathering information...",
            "Analyzing differences...",
            "Comparing features...",
            "Applying profile choices...",
            "Almost ready..."
        ]
    }

    var body: some View {
        Text(messages[index])
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: isVisible)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
                    withAnimation { isVisible = false }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        index = (index + 1) % messages.count
                        withAnimation { isVisible = true }
                    }
                }
            }
    }
}
// =======================================================
// SUMMARY CARD
// =======================================================

struct SummaryCardView: View {
    let machineA: String
    let machineB: String
    let categories: [Category]

    var winsA: Int { categories.filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == machineA }.count }
    var winsB: Int { categories.filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == machineB }.count }

    var generalPreferenceText: String {
        if winsA > winsB {
            if UserDefaults.userProfile != nil {
                return "\(machineA) is the stronger choice based on your profile"
            }
            return "\(machineA) wins across more categories"
        }

        if winsB > winsA {
            if UserDefaults.userProfile != nil {
                return "\(machineB) is the stronger choice based on your profile"
            }
            return "\(machineB) wins across more categories"
        }

        return "Both products have similar overall scores"
    }

    var body: some View {
        GlassCard(padding: 0) {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Text(machineA.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(winsA > winsB ? .white : .white.opacity(0.72))
                            .lineLimit(1)

                        Text("\(winsA)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(winsA > winsB ? .white : .white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(winsA > winsB ? 1.0 : (winsB > winsA ? 0.65 : 1.0))
                    .scaleEffect(winsA > winsB ? 1.02 : 1.0)

                    Text("–")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.32))

                    VStack(spacing: 4) {
                        Text(machineB.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(winsB >= winsA ? .white : .white.opacity(0.72))
                            .lineLimit(1)

                        Text("\(winsB)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(winsB >= winsA ? .white : .white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(winsB > winsA ? 1.0 : (winsA > winsB ? 0.65 : 1.0))
                    .scaleEffect(winsB > winsA ? 1.02 : 1.0)
                }
                .padding(.top, 26)
                .padding(.horizontal, 24)

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.72))

                        Text("General Preference")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.72))
                    }

                    Text(generalPreferenceText)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Text("Compared with CompareXY")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
                    .padding(.bottom, 24)
            }
        }
    }
}

// =======================================================
// FEATURED RESULT COMPONENTS
// =======================================================

struct GlassCard<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

struct DecisionBlockModel: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let tint: Color
}

struct ProductPalette {
    let start: Color
    let end: Color
    let accent: Color
}

struct SectionHeading: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(.white.opacity(0.62))
            }

            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ConfidenceBadge: View {
    let level: String

    private var accent: Color {
        switch level.lowercased() {
        case "high": return Color(red: 0.33, green: 0.85, blue: 0.66)
        case "moderate": return Color(red: 0.98, green: 0.77, blue: 0.30)
        default: return Color(red: 0.98, green: 0.50, blue: 0.42)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            Text("\(level.capitalized) confidence")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(Color(red: 0.16, green: 0.21, blue: 0.29))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1)
        )
    }
}

struct ProductArtworkView: View {
    let name: String
    let productType: String
    let palette: ProductPalette
    let isWinner: Bool

    private var symbolName: String {
        let joined = "\(name.lowercased()) \(productType.lowercased())"

        if joined.contains("iphone") || joined.contains("phone") || joined.contains("pixel") || joined.contains("galaxy") {
            return "iphone.gen3"
        }
        if joined.contains("macbook") || joined.contains("laptop") || joined.contains("notebook") {
            return "laptopcomputer"
        }
        if joined.contains("camera") {
            return "camera.fill"
        }
        if joined.contains("watch") {
            return "applewatch"
        }
        if joined.contains("headphone") || joined.contains("airpods") {
            return "headphones"
        }
        if joined.contains("speaker") {
            return "hifispeaker.fill"
        }
        if joined.contains("car") || joined.contains("tesla") {
            return "car.fill"
        }
        if joined.contains("coffee") || joined.contains("espresso") {
            return "cup.and.saucer.fill"
        }
        if joined.contains("tv") {
            return "tv.fill"
        }
        if joined.contains("tablet") || joined.contains("ipad") {
            return "ipad"
        }

        return "shippingbox.fill"
    }

    private var initials: String {
        let words = name.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isWinner ? palette.start : Color(red: 0.17, green: 0.22, blue: 0.30))

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                Image(systemName: symbolName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)

                Text(initials)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule(style: .continuous))
            }
            .padding(18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isWinner ? 0.28 : 0.16), lineWidth: 1)
        )
        .frame(height: 148)
    }
}

struct HeroProductTile: View {
    let name: String
    let productType: String
    let score: Int
    let total: Int
    let palette: ProductPalette
    let isWinner: Bool
    let isTie: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProductArtworkView(
                name: name,
                productType: productType,
                palette: palette,
                isWinner: isWinner
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    if isTie {
                        Text("Even")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.86))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule(style: .continuous))
                    } else if isWinner {
                        Text("Winner")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule(style: .continuous))
                    }
                }

                Text("\(score) of \(total) categories")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.72))

                Text("\(score)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(isWinner ? Color(red: 0.15, green: 0.24, blue: 0.33) : Color(red: 0.11, green: 0.16, blue: 0.23))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(isWinner ? 0.28 : 0.12), lineWidth: 1)
        )
    }
}

struct ScoreBarRow: View {
    let title: String
    let score: Int
    let total: Int
    let palette: ProductPalette
    let isWinner: Bool

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(score) / CGFloat(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.10))

                    Capsule(style: .continuous)
                        .fill(palette.start)
                        .frame(width: max(24, proxy.size.width * progress))
                }
            }
            .frame(height: 12)
            .overlay(alignment: .trailing) {
                if isWinner {
                    Text("Lead")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.86))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule(style: .continuous))
                        .offset(y: -18)
                }
            }
        }
    }
}

struct DecisionBlockCard: View {
    let block: DecisionBlockModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(block.tint.opacity(0.20))
                    .frame(width: 42, height: 42)

                Image(systemName: block.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(block.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(block.body)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.13, green: 0.18, blue: 0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct BulletPointRow: View {
    let text: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AmazonProductCard: View {
    let name: String
    let productType: String
    let palette: ProductPalette
    let url: URL
    let isWinner: Bool

    var body: some View {
        Link(destination: url) {
            VStack(alignment: .leading, spacing: 16) {
                ProductArtworkView(
                    name: name,
                    productType: productType,
                    palette: palette,
                    isWinner: isWinner
                )

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("View on Amazon")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.74))
                }

                Text(name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(isWinner ? "Recommended buy" : "Compare price and availability")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.78))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isWinner ? Color(red: 0.15, green: 0.24, blue: 0.33) : Color(red: 0.11, green: 0.16, blue: 0.23))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(isWinner ? 0.24 : 0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ComparisonCategoryCard: View {
    let title: String
    let winnerText: String
    let justification: String

    var body: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer(minLength: 12)

                    Text(winnerText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule(style: .continuous))
                }

                Text(justification)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ResultInfoSection: Identifiable {
    let id = UUID()
    let title: String
    let bullets: [String]
}

struct InfoCard: View {
    var title: String
    var bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }
}

// =======================================================
struct ResultView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var machineA: String
    var machineB: String
    
    @State private var response: AIComparisonResponse?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var relatedComparisons: [(String, String)] = []

    private func amazonButtonBackground(isWinner: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(isWinner ? 0.18 : 0.12))
    }

    private func amazonButtonOverlay(isWinner: Bool) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(isWinner ? 0.28 : 0.18), lineWidth: 1.2)
    }

    @ViewBuilder
    private func amazonButton(label: String, productName: String, isWinner: Bool, isLoser: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cart.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(productName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.72))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(amazonButtonBackground(isWinner: isWinner))
        .overlay(amazonButtonOverlay(isWinner: isWinner))
        .opacity(isWinner ? 1.0 : (isLoser ? 0.65 : 1.0))
        .scaleEffect(isWinner ? 1.02 : 1.0)
    }

    private func palette(for name: String) -> ProductPalette {
        let palettes: [ProductPalette] = [
            ProductPalette(
                start: Color(red: 0.14, green: 0.60, blue: 0.95),
                end: Color(red: 0.34, green: 0.88, blue: 0.86),
                accent: Color(red: 0.34, green: 0.88, blue: 0.86)
            ),
            ProductPalette(
                start: Color(red: 0.48, green: 0.41, blue: 0.96),
                end: Color(red: 0.91, green: 0.45, blue: 0.73),
                accent: Color(red: 0.91, green: 0.45, blue: 0.73)
            ),
            ProductPalette(
                start: Color(red: 0.97, green: 0.57, blue: 0.29),
                end: Color(red: 0.98, green: 0.79, blue: 0.36),
                accent: Color(red: 0.98, green: 0.79, blue: 0.36)
            ),
            ProductPalette(
                start: Color(red: 0.20, green: 0.77, blue: 0.53),
                end: Color(red: 0.17, green: 0.56, blue: 0.96),
                accent: Color(red: 0.20, green: 0.77, blue: 0.53)
            )
        ]

        let seed = name.unicodeScalars.map(\.value).reduce(0, +)
        return palettes[Int(seed) % palettes.count]
    }

    private func winnerName(scoreA: Int, scoreB: Int) -> String? {
        if scoreA > scoreB { return machineA }
        if scoreB > scoreA { return machineB }
        return nil
    }

    private func reasonsForWinner(
        response: AIComparisonResponse,
        winner: String?,
        categories: [Category]
    ) -> [String] {
        if winner == machineA {
            let strengths = response.strengths.productA.filter { !$0.isEmpty }
            if !strengths.isEmpty { return Array(strengths.prefix(3)) }
        }

        if winner == machineB {
            let strengths = response.strengths.productB.filter { !$0.isEmpty }
            if !strengths.isEmpty { return Array(strengths.prefix(3)) }
        }

        if let winner {
            let fallback = categories
                .filter { normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == winner }
                .map { "\($0.name): \($0.justification)" }
            return Array(fallback.prefix(3))
        }

        return categories.prefix(3).map { "\($0.name): \($0.justification)" }
    }

    private func tradeOffsForWinner(response: AIComparisonResponse, winner: String?) -> [String] {
        if winner == machineA {
            return Array(response.tradeOffs.productA.filter { !$0.isEmpty }.prefix(2))
        }

        if winner == machineB {
            return Array(response.tradeOffs.productB.filter { !$0.isEmpty }.prefix(2))
        }

        return []
    }

    private func decisionBlocks(
        response: AIComparisonResponse,
        winner: String?,
        isTie: Bool
    ) -> [DecisionBlockModel] {
        var blocks: [DecisionBlockModel] = []

        blocks.append(
            DecisionBlockModel(
                icon: isTie ? "equal.circle.fill" : "sparkles",
                title: isTie ? "Close call" : "Best overall pick",
                body: isTie ? "These products finish neck and neck. Personal preference should break the tie." : "\(winner ?? machineA) comes out ahead based on the weighted category wins.",
                tint: Color(red: 0.33, green: 0.85, blue: 0.66)
            )
        )

        let whoShouldBuyText: String
        if winner == machineA {
            whoShouldBuyText = response.whoShouldBuy.productA
        } else if winner == machineB {
            whoShouldBuyText = response.whoShouldBuy.productB
        } else {
            whoShouldBuyText = response.useCaseRecommendation
        }

        if !whoShouldBuyText.isEmpty {
            blocks.append(
                DecisionBlockModel(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Best for",
                    body: whoShouldBuyText,
                    tint: Color(red: 0.30, green: 0.68, blue: 0.98)
                )
            )
        }

        if let trending = response.trendingProduct,
           let newer = response.newerModel {
            let trend = trendSentence(trending: trending, newer: newer)
            if !trend.isEmpty {
                blocks.append(
                    DecisionBlockModel(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Market signal",
                        body: trend,
                        tint: Color(red: 0.98, green: 0.77, blue: 0.30)
                    )
                )
            }
        }

        if blocks.count < 3 {
            blocks.append(
                DecisionBlockModel(
                    icon: "text.bubble.fill",
                    title: "AI summary",
                    body: response.useCaseRecommendation,
                    tint: Color(red: 0.87, green: 0.49, blue: 0.74)
                )
            )
        }

        return Array(blocks.prefix(3))
    }

    private func resultWinner(for response: AIComparisonResponse) -> String {
        if response.whoShouldBuy.productA.localizedCaseInsensitiveContains(machineA) {
            return machineA
        }

        if response.whoShouldBuy.productB.localizedCaseInsensitiveContains(machineB) {
            return machineB
        }

        return score(for: machineA, response: response) >= score(for: machineB, response: response) ? machineA : machineB
    }

    private func score(for product: String, response: AIComparisonResponse) -> Int {
        response.categories.filter {
            normalizeWinner($0.winner, machineA: machineA, machineB: machineB) == product
        }.count
    }

    private func displayCategoryTitle(_ categoryName: String) -> String {
        let normalized = categoryName.lowercased()
        if normalized.contains("price") || normalized.contains("value") {
            return "Better value"
        }
        return categoryName
    }

    private func infoSections(for response: AIComparisonResponse, winner: String) -> [ResultInfoSection] {
        let winnerStrengths = winner == machineA ? response.strengths.productA : response.strengths.productB
        let winnerTradeoffs = winner == machineA ? response.tradeOffs.productA : response.tradeOffs.productB

        var sections: [ResultInfoSection] = []

        let trimmedStrengths = winnerStrengths.filter { !$0.isEmpty }
        if !trimmedStrengths.isEmpty {
            sections.append(ResultInfoSection(title: "Why \(winner) wins", bullets: trimmedStrengths))
        }

        let trimmedTradeoffs = winnerTradeoffs.filter { !$0.isEmpty }
        if !trimmedTradeoffs.isEmpty {
            sections.append(ResultInfoSection(title: "Trade-offs", bullets: trimmedTradeoffs))
        }

        let categoryBullets = response.categories.map { "\($0.name): \($0.justification)" }
        if !categoryBullets.isEmpty {
            sections.append(ResultInfoSection(title: "Category breakdown", bullets: categoryBullets))
        }

        return sections
    }

    @ViewBuilder
    private func scoreCard(title: String, score: Int, isWinner: Bool) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text("\(score)")
                .font(.system(size: 40, weight: .bold))

            Text("points")
                .font(.caption)
                .foregroundColor(isWinner ? .white.opacity(0.8) : .white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isWinner ? Color.accentPrimary : Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(isWinner ? 0.18 : 0.10), lineWidth: 1)
        )
        .foregroundColor(.white)
        .opacity(isWinner ? 1.0 : 0.6)
        .scaleEffect(isWinner ? 1.05 : 1.0)
    }

    @ViewBuilder
    private func categoryRow(_ category: Category) -> some View {
        let normalizedWinner = normalizeWinner(
            category.winner,
            machineA: machineA,
            machineB: machineB
        )

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text(normalizedWinner == "Tie" ? "Tie" : normalizedWinner)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.78))
            }

            Text(category.justification)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func amazonSearchLink(for product: String) -> String {
        let query = product.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? product
        return "https://www.amazon.com/s?k=\(query)"
    }

    @ViewBuilder
    private func topAmazonButton(title: String, link: String) -> some View {
        if let url = URL(string: link) {
            Link(destination: url) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "cart")
                        Text("View on Amazon")
                    }
                    .font(.system(size: 14, weight: .semibold))

                    Text(title)
                        .font(.system(size: 12))
                        .opacity(0.8)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func actionButtons(response: AIComparisonResponse, winner: String) -> some View {
        VStack(spacing: 14) {
            let winnerIsA = response.winner == machineA

            let winnerLinkString = winnerIsA
                ? (response.amazonLinkA ?? amazonSearchLink(for: machineA))
                : (response.amazonLinkB ?? amazonSearchLink(for: machineB))

            if let winnerURL = URL(string: winnerLinkString) {
                Link(destination: winnerURL) {
                    Text("Buy Winner")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                let linkA = response.amazonLinkA ?? amazonSearchLink(for: machineA)
                let linkB = response.amazonLinkB ?? amazonSearchLink(for: machineB)

                if let urlA = URL(string: linkA) {
                    Link(destination: urlA) {
                        Text(machineA)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                if let urlB = URL(string: linkB) {
                    Link(destination: urlB) {
                        Text(machineB)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: {
                shareImage = renderShareCard(
                    machineA: machineA,
                    machineB: machineB,
                    response: response
                )
                showShareSheet = true
            }) {
                Text("Share")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    var body: some View {
        
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.45, blue: 0.47),
                    Color(red: 0.10, green: 0.65, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 30) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    LoadingTextView()
                }
            } else if hasError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("Something went wrong")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Button("Try Again") {
                        isLoading = true
                        hasError = false
                        Task { await runComparison() }
                    }
                    .foregroundColor(.white)
                    Button("Go Back") { dismiss() }
                        .foregroundColor(.white)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let response = response {
                            let winner = resultWinner(for: response)
                            let summaryText = response.summary ?? response.useCaseRecommendation
                            let scoreA = response.scoreA ?? score(for: machineA, response: response)
                            let scoreB = response.scoreB ?? score(for: machineB, response: response)
                            let winnerText = response.winner ?? winner

                            HStack {
                                Button { dismiss() } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .font(.system(size: 38, weight: .bold))
                                }
                                Spacer()
                            }
                            .padding(.top, 16)

                            VStack(spacing: 8) {
                                Text("Comparison Guide")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)

                                Text("\(machineA.uppercased()) vs \(machineB.uppercased())")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 16) {
                                topAmazonButton(
                                    title: machineA,
                                    link: response.amazonLinkA ?? amazonSearchLink(for: machineA)
                                )

                                topAmazonButton(
                                    title: machineB,
                                    link: response.amazonLinkB ?? amazonSearchLink(for: machineB)
                                )
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Summary")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)

                                Text(summaryText)
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)

                                if let trending = response.trendingProduct,
                                   let newer = response.newerModel {
                                    let trend = trendSentence(trending: trending, newer: newer)
                                    if !trend.isEmpty {
                                        Text(trend)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white.opacity(0.88))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            GlassCard(padding: 0) {
                                VStack(spacing: 18) {
                                    HStack {
                                        VStack(spacing: 6) {
                                            Text(machineA.uppercased())
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(machineA == winner ? 1.0 : 0.7))
                                                .lineLimit(1)

                                            Text("\(scoreA)")
                                                .font(.system(size: 34, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .opacity(machineA == winner ? 1.0 : 0.65)
                                        .scaleEffect(machineA == winner ? 1.02 : 1.0)

                                        Text("–")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))

                                        VStack(spacing: 6) {
                                            Text(machineB.uppercased())
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(machineB == winner ? 1.0 : 0.7))
                                                .lineLimit(1)

                                            Text("\(scoreB)")
                                                .font(.system(size: 34, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .opacity(machineB == winner ? 1.0 : 0.65)
                                        .scaleEffect(machineB == winner ? 1.02 : 1.0)
                                    }
                                    .padding(.top, 24)
                                    .padding(.horizontal, 24)

                                    Rectangle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 1)
                                        .padding(.horizontal, 24)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("General Preference")
                                            .foregroundColor(.white.opacity(0.7))

                                        Text("\(winnerText) is the stronger choice")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.horizontal, 24)

                                    Text("Compared with CompareXY")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 4)
                                        .padding(.bottom, 24)
                                }
                            }

                            VStack(spacing: 16) {
                                ForEach(response.categories) { category in
                                    let normalizedWinner = normalizeWinner(
                                        category.winner,
                                        machineA: machineA,
                                        machineB: machineB
                                    )

                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Text(displayCategoryTitle(category.name))
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                                .fixedSize(horizontal: false, vertical: true)

                                            Spacer(minLength: 12)

                                            Text(normalizedWinner == "Tie" ? "🤝 Tie" : "🏆 \(normalizedWinner)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.15))
                                                .clipShape(Capsule(style: .continuous))
                                        }

                                        Text(category.justification)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.92))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(24)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                }
                            }

                            actionButtons(response: response, winner: winner)

                            Spacer(minLength: 40)
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await runComparison()
        }
        .onAppear {
            loadRelatedComparisons(for: machineA)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage, let response = response {
                ShareCardSheet(
                    machineA: machineA,
                    machineB: machineB,
                    image: image,
                    response: response
                )
            } else {
                EmptyView()
            }
        }
        
    }
    
    // MARK: - Render Share Card
    private func renderShareCard(machineA: String, machineB: String, response: AIComparisonResponse) -> UIImage {
        let bgGradient = LinearGradient(
            colors: [
                Color(red: 0.00, green: 0.82, blue: 0.85),
                Color(red: 0.00, green: 0.65, blue: 0.75)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        let card = VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 6)
                .padding(.top, 8)
            
            Text("Your CompareXY Result")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
            
            Text("\(machineA) vs \(machineB)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.22)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.30), lineWidth: 1))
            
            VStack(spacing: 12) {
                ForEach(Array(response.categories.prefix(5)).indices, id: \.self) { idx in
                    let cat = response.categories[idx]
                    let winner = normalizeWinner(cat.winner, machineA: machineA, machineB: machineB)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cat.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text(cat.justification)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                        Spacer()
                        Text("🏆")
                            .font(.system(size: 18))
                            .opacity(winner == "Tie" ? 0.0 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.32),
                                        Color.white.opacity(0.22)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }
            }
            
            Text("Share Card")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.00, green: 0.75, blue: 0.85), Color(red: 0.30, green: 0.50, blue: 0.90)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 2)
                .padding(.bottom, 10)
        }
            .padding(18)
            .frame(width: 330)
            .background(bgGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: card)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage { return uiImage }
        }
        
        let controller = UIHostingController(rootView: card)
        controller.view.bounds = CGRect(x: 0, y: 0, width: 330, height: controller.view.intrinsicContentSize.height)
        let size = controller.view.intrinsicContentSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
    
    // MARK: - Share to Social
    private func shareToSocial(_ platform: String, response: AIComparisonResponse) {
        let image = renderShareCard(machineA: machineA, machineB: machineB, response: response)
        let text = "\(machineA) vs \(machineB) — compared with CompareXY! 🏆"
        let av = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootVC = window.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    // MARK: - Run Comparison
    @MainActor
    private func runComparison() async {
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 30_000_000_000)
            
            await MainActor.run {
                if isLoading {
                    print("⏰ TIMEOUT TRIGGERED")
                    hasError = true
                    isLoading = false
                }
            }
        }
        
        do {
            let result = try await AIService.shared.compare(
                machineA: machineA,
                machineB: machineB,
                priority: UserDefaults.compPriority,
                budget: UserDefaults.compBudget,
                switching: UserDefaults.compSwitching
            )
            
            // ✅ SET RESPONSE
            response = result
            
            // ✅ DEBUG PRINTS (IMPORTANT)
            print("RESPONSE:", response != nil)
            print("LOADING (before end):", isLoading)
            print("ERROR:", hasError)
            
            timeoutTask.cancel()
            
            // Optional save
            if result.productType != "Unsupported" {
                do {
                    let user = try await SupabaseManager.shared.client.auth.user()
                    try await SupabaseManager.shared.client
                        .from("Comparisons")
                        .insert([
                            "product_a": machineA,
                            "product_b": machineB,
                            "result": result.useCaseRecommendation,
                            "user_id": user.id.uuidString
                        ])
                        .execute()
                    
                    print("SAVE SUCCESS")
                } catch {
                    print("SAVE ERROR:", error)
                }
            }
            
        } catch {
            timeoutTask.cancel()
            hasError = true
            print("COMPARE ERROR:", error)
        }
        
        // ✅ ALWAYS END HERE
        isLoading = false
        
        // ✅ FINAL STATE DEBUG
        print("FINAL → RESPONSE:", response != nil)
        print("FINAL → LOADING:", isLoading)
        print("FINAL → ERROR:", hasError)
    }
    
    // MARK: - Load Related Comparisons
    func loadRelatedComparisons(for product: String) {
        Task {
            do {
                let response = try await SupabaseManager.shared.client
                    .from("Comparisons")
                    .select()
                    .or("product_a.eq.\(product),product_b.eq.\(product)")
                    .order("created_at", ascending: false)
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
                await MainActor.run {
                    relatedComparisons = fetched
                }
            } catch {
                print("Related Comparisons error:", error)
            }
        }
    }
    private func trendSentence(trending: String, newer: String) -> String {
        
        // 🔥 Strong cases first (most persuasive)
        
        if trending == "A" && newer == "A" {
            return "\(machineA) is currently the most popular choice among buyers"
        }
        
        if trending == "B" && newer == "B" {
            return "\(machineB) is currently the most popular choice among buyers"
        }
        
        // 🎯 Split signals (this is key for decision-making)
        
        if trending == "A" && newer == "B" {
            return "\(machineA) is trending right now, while \(machineB) is the newer model"
        }
        
        if trending == "B" && newer == "A" {
            return "\(machineB) is trending right now, while \(machineA) is the newer model"
        }
        
        // ⚖️ Balanced / neutral
        
        if trending == "Both" {
            return "Both models are popular choices, with slightly different strengths"
        }
        
        // fallback
        
        return ""
    }
    // =======================================================
    // SOCIAL BUTTON
    // =======================================================
    
    struct SocialButton: View {
        let icon: String
        let label: String
        let color: Color
        var isSystem: Bool = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 54, height: 54)
                        if isSystem {
                            Image(systemName: icon)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: socialIcon(icon))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        
        private func socialIcon(_ name: String) -> String {
            switch name {
            case "instagram": return "camera.fill"
            case "facebook": return "f.circle.fill"
            case "tiktok": return "music.note"
            default: return "square.and.arrow.up"
            }
        }
    }
    
    // =======================================================
    // SHARE CARD SHEET
    // =======================================================
    
    struct ShareCardSheet: View {
        @Environment(\.dismiss) var dismiss
        let machineA: String
        let machineB: String
        let image: UIImage
        let response: AIComparisonResponse
        
        @State private var showActivity = false
        
        var body: some View {
            ZStack {
                LinearGradient.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Your CompareXY Result")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(machineA) vs \(machineB)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.22))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(response.categories) { cat in
                                let winner = normalizeWinner(cat.winner, machineA: machineA, machineB: machineB)
                                HStack {
                                    Text(winner == machineA ? "🏆" : "  ").frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cat.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(cat.justification)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(winner == machineB ? "🏆" : "  ").frame(width: 28)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.16)))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button { showActivity = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Share Card")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.75, blue: 0.85), Color(red: 0.30, green: 0.50, blue: 0.90)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                Text("As an Amazon Associate we earn from qualifying purchases")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                    .padding(.top, 20)
            }
            
            .sheet(isPresented: $showActivity) {
                ActivityView(activityItems: [image])
            }
        }
    }
    
    // =======================================================
    // ACTIVITY VIEW
    // =======================================================
    
    struct ActivityView: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil
        var excludedActivityTypes: [UIActivity.ActivityType]? = nil
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            controller.excludedActivityTypes = excludedActivityTypes
            if let pop = controller.popoverPresentationController {
                pop.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 60, width: 0, height: 0)
                pop.sourceView = UIApplication.shared.windows.first
            }
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
        
    }
    
}
