import Foundation

struct ScannedItem: Identifiable, Hashable, Codable {
    let id: UUID
    let code: String
    var name: String
    var quantity: Int

    init(id: UUID = UUID(), code: String, name: String, quantity: Int) {
        self.id = id
        self.code = code
        self.name = name
        self.quantity = quantity
    }

    static private let storageKey = "scannedItems"

    static func loadAll() -> [ScannedItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([ScannedItem].self, from: data) else {
            return []
        }
        return items
    }

    static func saveAll(_ items: [ScannedItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
