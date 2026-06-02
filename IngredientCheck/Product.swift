//
//  Product.swift
//  IngredientCheck
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
    let ingredients: [OFFIngredient]?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case ingredientsText = "ingredients_text"
        case imageUrl = "image_small_url"
        case brands
        case ingredients
    }
}
