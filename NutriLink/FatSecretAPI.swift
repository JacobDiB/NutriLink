import Foundation

// MARK: - Token Response

struct FatSecretTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String
}

// MARK: - Food Search Response (v2)

struct FatSecretFoodSearchResponse: Decodable {

    struct Foods: Decodable {

        struct Food: Decodable, Identifiable {
            let id: String
            let name: String
            let description: String?
            let brand: String?

            enum CodingKeys: String, CodingKey {
                case id = "food_id"
                case name = "food_name"
                case description = "food_description"
                case brand = "brand_name"
            }
        }

        struct Results: Decodable {
            let food: [Food]?
        }

        let results: Results
    }

    let foods_search: Foods
}

// MARK: - API Client

final class FatSecretAPI {

    static let shared = FatSecretAPI()

    private var accessToken: String?
    private var tokenExpiryDate: Date?

    private let clientId = "c64cf9044d46480f9f53c34e02f465fc"
    private let clientSecret = "88baca8843f7432b872a05839ac9cf27"

    private init() {}

    // MARK: - Public: Search foods

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
        print("👉 [FatSecret] Searching foods with URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("👉 [FatSecret] searchFoods status code: \(http.statusCode)")
            }

            // DEBUG: print raw body
            if let bodyString = String(data: data, encoding: .utf8) {
                print("👉 [FatSecret] searchFoods raw response:\n\(bodyString)")
            }

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
            print("❌ [FatSecret] searchFoods error: \(error)")
            throw error
        }
    }

    // MARK: - Token handling

    private func ensureValidToken() async throws {
        if let expiry = tokenExpiryDate,
           let _ = accessToken,
           expiry.timeIntervalSinceNow > 60 {
            return
        }

        try await fetchAccessToken()
    }

    private func fetchAccessToken() async throws {
        let url = URL(string: "https://oauth.fatsecret.com/connect/token")!
        print("👉 [FatSecret] Fetching token from: \(url.absoluteString)")

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

            if let http = response as? HTTPURLResponse {
                print("👉 [FatSecret] fetchAccessToken status code: \(http.statusCode)")
            }

            if let bodyString = String(data: data, encoding: .utf8) {
                print("👉 [FatSecret] fetchAccessToken raw response:\n\(bodyString)")
            }

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
            print("❌ [FatSecret] fetchAccessToken error: \(error)")
            throw error
        }
    }
}

