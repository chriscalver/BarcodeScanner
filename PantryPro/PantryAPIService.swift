import Foundation

struct PantryItem: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let location: String
    let imageUrl: String
    let imageName: String
    let size: String
    let extraStrOne: String
    let extraStrTwo: String
    let isActive: Int
    let extraIntOne: Int
    let extraIntTwo: Int
    let lastPurchase: String
    let lastUpdated: String
    let isHot: Bool
}

class PantryAPIService: ObservableObject {
    @Published var items: [PantryItem] = []
    @Published var errorMessage: String? = nil
    
    func fetchPantryItems() {
        guard let url = URL(string: "https://www.chriscalver.com/ApiTest/api/Pantry") else {
            self.errorMessage = "Invalid URL"
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data returned"
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode([PantryItem].self, from: data)
                DispatchQueue.main.async {
                    self.items = decoded
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func sendMockPantryItem(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://www.chriscalver.com/ApiTest/api/Pantry") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        let mockItem = PantryItem(
            id: 0, // The server may assign the ID
            name: "Mock Sauce",
            description: "A test sauce",
            location: "A1",
            imageUrl: "",
            imageName: "",
            size: "Large",
            extraStrOne: "Extra1",
            extraStrTwo: "Extra2",
            isActive: 1,
            extraIntOne: 42,
            extraIntTwo: 99,
            lastPurchase: "2025-08-14T12:00:00.000Z",
            lastUpdated: "2025-08-14T12:00:00.000Z",
            isHot: false
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(mockItem)
            request.httpBody = data
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Invalid response", code: 0)))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }.resume()
    }
    
    func deletePantryItem(id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://www.chriscalver.com/ApiTest/api/Pantry/\(id)") else {
            print("[DEBUG] Delete: Invalid URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        print("[DEBUG] Delete: URL = \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] Delete: Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                print("[DEBUG] Delete: Status = \(httpResponse.statusCode), Body = \(responseBody)")
                if [200, 202, 204].contains(httpResponse.statusCode) {
                    DispatchQueue.main.async {
                        self.fetchPantryItems()
                        completion(.success(()))
                    }
                } else {
                    let err = NSError(domain: "Delete failed", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody])
                    DispatchQueue.main.async {
                        completion(.failure(err))
                    }
                }
            } else {
                print("[DEBUG] Delete: No HTTPURLResponse")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No HTTPURLResponse", code: 0)))
                }
            }
        }.resume()
    }
    
    func addPantryItem(name: String, description: String, quantity: Int, size: String, location: String, isHot: Bool, extraStrOne: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Normalize barcode for comparison
        let normalizedBarcode = extraStrOne.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if items.contains(where: { $0.extraStrOne.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedBarcode }) {
            let error = NSError(domain: "Duplicate barcode", code: 1, userInfo: [NSLocalizedDescriptionKey: "This barcode already exists in your pantry."])
            self.errorMessage = error.localizedDescription
            completion(.failure(error))
            return
        }
        guard let url = URL(string: "https://www.chriscalver.com/ApiTest/api/Pantry") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        // Generate current date string in required ISO8601 format with Z
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = isoFormatter.string(from: now)
        let newItem = PantryItem(
            id: 0, // The server may assign the ID
            name: name,
            description: description,
            location: location,
            imageUrl: "",
            imageName: "",
            size: size,
            extraStrOne: normalizedBarcode, // Use normalized barcode
            extraStrTwo: "Extra2",
            isActive: 1,
            extraIntOne: quantity, // Use for Quantity
            extraIntTwo: 99,
            lastPurchase: nowString,
            lastUpdated: nowString,
            isHot: isHot
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(newItem)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Outgoing PantryItem JSON: \(jsonString)")
            }
            request.httpBody = data
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                if (200...299).contains(httpResponse.statusCode) {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                } else {
                    // Check for duplicate error in response body
                    if responseBody.localizedCaseInsensitiveContains("duplicate") || responseBody.localizedCaseInsensitiveContains("already exists") {
                        let err = NSError(domain: "Duplicate barcode", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "This barcode already exists in your pantry."])
                        DispatchQueue.main.async {
                            completion(.failure(err))
                        }
                    } else {
                        let err = NSError(domain: "API error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody])
                        DispatchQueue.main.async {
                            completion(.failure(err))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No HTTPURLResponse", code: 0)))
                }
            }
        }.resume()
    }
    
    func updatePantryItem(_ item: PantryItem, completion: @escaping (Result<Void, Error>) -> Void) {
        // Use id as a query parameter, not as a path segment
        guard let url = URL(string: "https://www.chriscalver.com/ApiTest/api/Pantry?id=\(item.id)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(item)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Outgoing PantryItem JSON (UPDATE): \(jsonString)")
            }
            request.httpBody = data
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("[DEBUG] Network error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                    print("[DEBUG] API error: status=\(httpResponse.statusCode), body=\(responseBody)")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "API error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody])))
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.fetchPantryItems()
                completion(.success(()))
            }
        }.resume()
    }
}
