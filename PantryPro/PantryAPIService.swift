import Foundation

struct PantryItem: Codable, Identifiable {
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
            lastPurchase: "2025-08-14T12:00:00.000",
            lastUpdated: "2025-08-14T12:00:00.000",
            isHot: false
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let data = try JSONEncoder().encode(mockItem)
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
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
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
}
