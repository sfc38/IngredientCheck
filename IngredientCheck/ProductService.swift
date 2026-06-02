//
//  ProductService.swift
//  IngredientCheck
//

import Foundation

enum ProductFetchError: Error, LocalizedError {
    case notFound
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notFound:      return "Product not found."
        case .networkError:  return "No internet connection or request failed."
        case .decodingError: return "Unable to read product data."
        }
    }
}

struct ProductService {
    func fetchProduct(barcode: String) async throws -> Product {
        guard let url = URL(string: "https://world.openfoodfacts.net/api/v2/product/\(barcode)") else {
            throw ProductFetchError.networkError
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw ProductFetchError.networkError
        }

        let decoded: ProductResponse
        do {
            decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
        } catch {
            throw ProductFetchError.decodingError
        }

        guard decoded.status == 1, let product = decoded.product else {
            throw ProductFetchError.notFound
        }
        return product
    }
}
