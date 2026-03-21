//
//  AmazonAffiliate.swift
//  CompareXY
//
//  Created by Vanessa Robine on 3/16/26.
//

import Foundation

struct AmazonAffiliate {
    static let tag = "comparexy-20"
    
    static func searchURL(for product: String) -> URL? {
        let query = product
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "+")
        let urlString = "https://www.amazon.com/s?k=\(query)&tag=\(tag)"
        return URL(string: urlString)
    }
}
