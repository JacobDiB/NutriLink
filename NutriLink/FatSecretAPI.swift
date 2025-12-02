//
//  NutriLinkApp.swift
//  NutriLink
//
//  Created by CS3714 on 11/5/25.
//

import Foundation

// OAuth token response returned by the FatSecret API
struct FatSecretTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String
}

// Top-level food search response from FatSecret
struct FatSecretFoodSearchResponse: Decodable {

    struct Foods: Decodable {

        // Represents a single food item returned by the API
        struct Food: Decodable, Identifiable {
            let id: String
            let name: String
            let description: String?
            let brand: String?
            let servings: Servings?

            enum CodingKeys: String, CodingKey {
                case id = "food_id"
                case name = "food_name"
                case description = "food_description"
                case brand = "brand_name"
                case servings
            }

            // Wrapper for the list of servings
            struct Servings: Decodable {
                let serving: [Serving]
            }

            // Nutritional information for a single serving
            struct Serving: Decodable {
                let calories: String?
                let fat: String?
                let carbohydrate: String?
                let protein: String?
                let sugar: String?
                let fiber: String?
                let sodium: String?
                let potassium: String?
                let calcium: String?
                let iron: String?

                let servingDescription: String?
                let metricServingAmount: String?
                let metricServingUnit: String?

                enum CodingKeys: String, CodingKey {
                    case calories
                    case fat
                    case carbohydrate
                    case protein
                    case sugar
                    case fiber
                    case sodium
                    case potassium
                    case calcium
                    case iron

                    case servingDescription = "serving_description"
                    case metricServingAmount = "metric_serving_amount"
                    case metricServingUnit = "metric_serving_unit"
                }
            }
        }

        struct Results: Decodable {
            let food: [Food]?
        }

        let results: Results
    }

    let foods_search: Foods
}

// Simple client wrapper around the FatSecret REST API
final class FatSecretAPI {

    static let shared = FatSecretAPI()

    private var accessToken: String?
    private var tokenExpiryDate: Date?

    private let clientId = "c64cf9044d46480f9f53c34e02f465fc"
    private let clientSecret = "88baca8843f7432b872a05839ac9cf27"

    private init() {}

    // Public method to search foods by a text query
    func searchFoods(query: String) async throws -> [FatSecretFoodSearchResponse.Foods.Food] {
        try await ensureValidToken()

        guard let token = accessToken else {
            throw NSError(
                domain: "FatSecretAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing access token"]
            )
        }

        var components = URLComponents(string: "https://platform.fatsecret.com/rest/foods/search/v2")!
        components.queryItems = [
            URLQueryItem(name: "search_expression", value: query),
            URLQueryItem(name: "max_results", value: "20"),
            URLQueryItem(name: "format", value: "json")
        ]

        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw NSError(
                    domain: "FatSecretAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "FatSecret error \(http.statusCode)"]
                )
            }

            let decoded = try JSONDecoder().decode(FatSecretFoodSearchResponse.self, from: data)
            return decoded.foods_search.results.food ?? []
        } catch {
            throw error
        }
    }

    // Make sure we have a valid token before calling the API
    private func ensureValidToken() async throws {
        if let expiry = tokenExpiryDate,
           let _ = accessToken,
           expiry.timeIntervalSinceNow > 60 {
            return
        }

        try await fetchAccessToken()
    }

    // Fetch a new access token using client credentials
    private func fetchAccessToken() async throws {
        let url = URL(string: "https://oauth.fatsecret.com/connect/token")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentialString = "\(clientId):\(clientSecret)"
        let base64Credentials = Data(credentialString.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let bodyParams: [String: String] = [
            "grant_type": "client_credentials",
            "scope": "premier"
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw NSError(
                    domain: "FatSecretAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Token error \(http.statusCode)"]
                )
            }

            let tokenResponse = try JSONDecoder().decode(FatSecretTokenResponse.self, from: data)
            self.accessToken = tokenResponse.access_token
            self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        } catch {
            throw error
        }
    }
}

