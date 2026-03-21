import Foundation
import Supabase
import PostgREST


// MARK: - Models

struct AIComparisonResponse: Codable {
    let productType: String
    let isPhysicalProduct: Bool?
    let trendingProduct: String?
    let newerModel: String?
    let categories: [Category]
    let whoShouldBuy: WhoShouldBuy
    let strengths: ProductStrengths
    let tradeOffs: ProductStrengths
    let useCaseRecommendation: String
    let confidenceLevel: String
    let winner: String?
    let summary: String?
    let scoreA: Int?
    let scoreB: Int?
    let sections: [ComparisonSection]?
    let amazonLinkA: String?
    let amazonLinkB: String?
    let categoryWinners: [CategoryWinner]?
}

struct WhoShouldBuy: Codable {
    let productA: String
    let productB: String
}


struct Category: Codable, Identifiable {
    let name: String
    let winner: String
    let justification: String
    

    var id: String { name }
}

struct ProductStrengths: Codable {
    let productA: [String]
    let productB: [String]
}

struct ComparisonSection: Codable {
    let title: String
    let bullets: [String]
}

struct CategoryWinner: Codable {
    let category: String
    let winner: String
}

struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - AI Service

class AIService {
    
    static let shared = AIService()
    private let apiKey = "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"
    
    private var cache: [String: AIComparisonResponse] = [:]
    private let supabase = SupabaseManager.shared.client
    
    func classifyProduct(_ name: String) async throws -> String {
        return "Other"
    }
    
    func compare(
        machineA: String,
        machineB: String,
        priority: String,
        budget: String,
        switching: String
    ) async throws -> AIComparisonResponse {
        
        
        // CLEAN INPUTS
        let a = ProductExtractor.clean(machineA).capitalized
        let b = ProductExtractor.clean(machineB).capitalized

        let cleanA = min(a, b)
        let cleanB = max(a, b)
        
        // Check cache first
        let cacheKey = "\(cleanA.lowercased())|\(cleanB.lowercased())|\(priority)|\(budget)|\(switching)"
        if let cached = cache[cacheKey] {
            print("CACHE HIT")
            return cached
        }
        
        // SUPABASE CACHE
        let cacheResponse = try await supabase
            .from("Comparisons")
            .select("result")
            .eq("product_a", value: cleanA)
            .eq("product_b", value: cleanB)
            .limit(1)
            .execute()

        if let rows = cacheResponse.value as? [[String: Any]],
           let first = rows.first,
           let result = first["result"] {

            let data = try JSONSerialization.data(withJSONObject: result)
            let decoded = try JSONDecoder().decode(AIComparisonResponse.self, from: data)

            print("SUPABASE CACHE HIT")

            cache[cacheKey] = decoded
            return decoded
        }
         
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Compare "\(cleanA)" (Product A) and "\(cleanB)" (Product B).
        
        First determine whether the two items belong to the same general product category.
        
        Step 1 — Determine the product category of Product A and Product B 
        (e.g., smartphone, laptop, beverage, car, software, clothing, medicine, etc). When a brand is provided (e.g., BMW, Tesla, Apple), assume the comparison refers to the main products produced by that brand.
        
        
        
        Step 2 — Only set "productType" to "Unsupported" for these specific cases:
        - Raw food, beverages, drinks (e.g., Coca-Cola, wine, beer, coffee, pizza, burger)
        - Restaurants or food service brands (e.g., McDonald's, Starbucks, Chipotle)
        - Clearly unrelated categories where no reasonable person would compare before buying
          (e.g., car vs video game console, laptop vs perfume, phone vs furniture, watch vs refrigerator)

        ALWAYS SUPPORTED — never mark these as Unsupported:
        - Kitchen appliances (Ninja, Instant Pot, Vitamix, KitchenAid, Cuisinart)
        - Coffee machines (Nespresso, Keurig, Breville, DeLonghi, Jura)
        - Any physical device, machine, or gadget regardless of its purpose
        - Cars, phones, laptops, headphones, watches, software, medications
        - Any two products from the same category

        When in doubt: if a reasonable person would genuinely compare these before buying, support it. Otherwise mark Unsupported. Only reject clearly non-physical food/drink items.
        
        Step 3 — Only generate comparison categories when both products belong 
        to the same category or very similar categories.
        User profile: \(UserDefaults.userProfile?.profileSummary ?? "General consumer, balanced preferences.")

        User preferences:
        - Priority: \(priority)
        - Budget sensitivity: \(budget)
        - Switching cost tolerance: \(switching)
        - "trendingProduct": "A", "B", "Both", or "Neither" — which product is more popular and searched right now based on current market trends
        - "newerModel": "A", "B", or "Same" — which product was released more recently
        
        Weight your category selection and winner decisions based on these preferences.
        
        Return STRICT JSON only using the following structure.
        
        Rules:
        • Generate 5 to 8 comparison categories that are most relevant for the product type.
        • The "winner" field MUST be exactly one of: "A", "B", or "Tie".
        • Never use product names in the winner field.
        • Each category MUST include a non-empty "justification".
        • The justification MUST be 1–2 concise sentences explaining WHY the winner wins.
        • Prefer concrete facts such as specs, measurable differences, well-known benchmarks, or documented features. Always include price.
        • For any price/value decision, reflect VALUE rather than automatically rewarding the cheaper option.
        • If both products are in a similar price range (difference under 20%), treat price as too similar and do not award a price/value win.
        • If one product is significantly cheaper (more than 20%) and still has similar overall score/features, it can win on value.
        • If a product is more expensive but clearly has better features/quality, do not penalize it for price and do not let price override strong feature advantages.
        • If you include a price-focused category, name it "Better value" and set the winner according to the value logic above.
        • If information is uncertain, say so rather than inventing details.
        • Never omit any field in the JSON structure.
        
        
        JSON format:
        {
          "productType": "",
          "isPhysicalProduct": true,
         "trendingProduct": "A",
          "newerModel": "A",
          "categories": [
          "categories": [
            {
              "id": "1",
              "name": "Category name",
              "winner": "A",
              "justification": "1–2 sentences explaining the decision with concrete details."
            }
          ],
          "whoShouldBuy": {
            "productA": "",
            "productB": ""
          },
          "strengths": {
            "productA": [],
            "productB": []
          },
          "tradeOffs": {
            "productA": [],
            "productB": []
          },
          "useCaseRecommendation": "Max 2 sentences.",
          "confidenceLevel": "Low | Moderate | High"
        - "isPhysicalProduct": true ONLY for products typically sold on Amazon (electronics, appliances, clothing, books, supplements, tools, home goods, headphones, cameras). Set to false for: software, apps, AI tools, streaming services, cars, vehicles, real estate, services, restaurants, and anything not typically sold on Amazon.
        }
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a concise product comparison engine. Return only valid JSON. Never include markdown or extra text."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard var content = decoded.choices.first?.message.content else {
            throw URLError(.cannotDecodeRawData)
        }
        
        content = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = content.data(using: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(AIComparisonResponse.self, from: jsonData)
            print("DECODE SUCCESS")
            print("Product Type:", decodedResponse.productType)
            print("Confidence:", decodedResponse.confidenceLevel)
            print("Categories:", decodedResponse.categories)
            print("isPhysicalProduct:", decodedResponse.isPhysicalProduct ?? "nil")
            if decodedResponse.productType == "Unsupported" {
                let fixed = AIComparisonResponse(
                    productType: "Unsupported",
                    isPhysicalProduct: false,
                    trendingProduct: nil,
                    newerModel: nil,
                    categories: [],
                    whoShouldBuy: WhoShouldBuy(productA: "", productB: ""),
                    strengths: ProductStrengths(productA: [], productB: []),
                    tradeOffs: ProductStrengths(productA: [], productB: []),
                    useCaseRecommendation: "Not Applicable.",
                    confidenceLevel: "High",
                    winner: nil,
                    summary: nil,
                    scoreA: nil,
                    scoreB: nil,
                    sections: nil,
                    amazonLinkA: nil,
                    amazonLinkB: nil,
                    categoryWinners: nil
                )
                cache[cacheKey] = fixed
                return fixed
            }
            cache[cacheKey] = decodedResponse
            return decodedResponse
        } catch {
            print("DECODING ERROR:", error)
            print("RAW JSON RECEIVED:", content)
            throw error
        }
    }
    
    func simplePrompt(_ prompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 150
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        guard let content = decoded.choices.first?.message.content else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let cleaned = content
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    func detectProductFromImage(base64: String) async throws -> String {
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "You are a product identification assistant. Identify the EXACT consumer product in this photo. Return ONLY the brand and model name. If you are unsure, return the most likely brand and model. Do not explain. Do not add extra words."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 50
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8)!)
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        return decoded.choices.first?.message.content ?? "Unknown product"
    }
}
