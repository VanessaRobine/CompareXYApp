//
//  ProductExtractor.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/6/26.
//

import Foundation

struct ProductExtractor {

    static func clean(_ input: String) -> String {

        // If it's not a URL, return text as is
        guard let url = URL(string: input), url.scheme != nil else {
            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let host = url.host ?? ""

        // Amazon link
        if host.contains("amazon") {
            return extractAmazonProduct(url)
        }

        // Apple link
        if host.contains("apple.com") {
            return extractAppleProduct(url)
        }

        // Default: use last part of URL
        return url.lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func extractAmazonProduct(_ url: URL) -> String {

        let components = url.pathComponents

        if let index = components.firstIndex(of: "dp"), index + 1 < components.count {
            let asin = components[index + 1]
            return "Amazon product \(asin)"
        }

        return "Amazon product"
    }

    static func extractAppleProduct(_ url: URL) -> String {

        let slug = url.lastPathComponent
            .replacingOccurrences(of: "-", with: " ")

        return slug.capitalized
    }
}
