import Foundation

struct ScannedItem: Identifiable, Hashable, Codable {
    let id: UUID
    let code: String
    var name: String
    var description: String // Added description property
    var quantity: Int
    var size: String // Added size property
    var location: String // Added location property
    var isHot: Bool // Added isHot property

    init(id: UUID = UUID(), code: String, name: String, description: String = "", quantity: Int, size: String = "", location: String = "", isHot: Bool = false) {
        self.id = id
        self.code = code
        self.name = name
        self.description = description
        self.quantity = quantity
        self.size = size
        self.location = location
        self.isHot = isHot
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
