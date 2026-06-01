//
//  ProductService.swift
//  IngredientCheck
//
//  Created by Fatih Catpinar on 3/29/26.
//

import Foundation

enum ProductFetchResult {
    case success(Product)
    case notFound
    case networkError
    case decodingError
}

class ProductService {
    func fetchProduct(barcode: String, completion: @escaping (ProductFetchResult) -> Void) {
        guard let url = URL(string: "https://world.openfoodfacts.net/api/v2/product/\(barcode)") else {
            DispatchQueue.main.async {
                completion(.networkError)
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                DispatchQueue.main.async {
                    completion(.networkError)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.networkError)
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)

                DispatchQueue.main.async {
                    if decoded.status == 1, let product = decoded.product {
                        completion(.success(product))
                    } else {
                        completion(.notFound)
                    }
                }
            } catch {
                print("JSON decode error: \(error)")
                DispatchQueue.main.async {
                    completion(.decodingError)
                }
            }
        }.resume()
    }
}
