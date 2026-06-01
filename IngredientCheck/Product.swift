//
//  Product.swift
//  IngredientCheck
//
//  Created by Fatih Catpinar on 3/29/26.
//

import Foundation

struct ProductResponse: Codable {
    let status: Int?
    let product: Product?
}

struct Product: Codable {
    let productName: String?
    let ingredientsText: String?
    let imageUrl: String?
    let brands: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case ingredientsText = "ingredients_text"
        case imageUrl = "image_small_url"
        case brands
    }
}
