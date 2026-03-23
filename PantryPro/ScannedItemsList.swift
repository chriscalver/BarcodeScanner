import SwiftUI

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ScannedItemsList: View {
    @ObservedObject var pantryAPIService: PantryAPIService
    var highlightedCode: String? = nil
    @State private var editingItem: PantryItem? = nil
    @State private var editedName: String = ""
    @State private var editedDescription: String = ""
    @State private var editedLocation: String = ""
    @State private var editedSize: String = ""
    @State private var editedIsHot: Bool = false
    @State private var errorMessage: ErrorMessage? = nil
    @State private var itemToDelete: PantryItem? = nil
    @State private var showDeleteAlert: Bool = false

    var items: [PantryItem] { pantryAPIService.items }

    var body: some View {
        // Use the same green as the checkmark for deterministic matching
        // Use the system checkmark green so the list matches `LogoWithCheckmarkView` exactly
        let baseGreen = Color(UIColor.systemGreen)
        let listBackground = baseGreen.opacity(0.06) // very light green background
        let cardColor = baseGreen.opacity(0.58) // slightly stronger green for cards

        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // Simple header
                VStack(spacing: 1) {
                    Image(systemName: "p.square.fill")
                        .font(.system(size: 98))
                        .foregroundColor(.blue)
                    Text("PantryPro")
                        .font(.title2)
                        .bold()
                    if let err = pantryAPIService.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 1)
                
                // Minimal list: only show the name for each item (custom rows for deterministic appearance)
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(item: item, pantryAPIService: pantryAPIService)) {
                                ZStack(alignment: .leading) {
                                    // Card background using a green derived from the pantry checkmark color
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardColor)
                                        .shadow(color: Color.black.opacity(0.09), radius: 3, x: 0, y: 1)

                                    Text(item.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 10)) // ensure tappable area covers the card
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
                // Remove per-ScrollView background; apply background to outer container so it always shows
                .onAppear {
                    print("[DEBUG] ScannedItemsList appeared — fetching pantry items")
                    // Don't trigger network fetch during SwiftUI previews
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                        pantryAPIService.fetchPantryItems()
                    }
                }
            }
            .background(listBackground.ignoresSafeArea()) // ensure background covers full screen/safe area
        }
        
         .sheet(item: $editingItem) { editingItem in
             NavigationView {
                 Form {
                     Section(header: Text("Edit Item")) {
                         VStack(alignment: .leading) {
                             Text("Name")
                                 .font(.caption)
                             TextField("Name", text: $editedName)
                         }
                         VStack(alignment: .leading) {
                             Text("Description")
                                 .font(.caption)
                             TextField("Description", text: $editedDescription)
                         }
                         VStack(alignment: .leading) {
                             Text("Location")
                                 .font(.caption)
                             TextField("Location", text: $editedLocation)
                         }
                         VStack(alignment: .leading) {
                             Text("Size")
                                 .font(.caption)
                             TextField("Size", text: $editedSize)
                         }
                         Toggle(isOn: $editedIsHot) {
                             Text("Hot")
                         }
                     }
                 }
                 .navigationBarTitle("Edit Item", displayMode: .inline)
                 .navigationBarItems(leading: Button("Cancel") {
                     self.editingItem = nil
                 }, trailing: Button("Save") {
                     // Set lastUpdated to current time in required format
                     let formatter = DateFormatter()
                     formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                     let nowString = formatter.string(from: Date())
                     let updatedItem = PantryItem(
                         id: editingItem.id,
                         name: editedName,
                         description: editedDescription,
                         location: editedLocation,
                         imageUrl: editingItem.imageUrl,
                         imageName: editingItem.imageName,
                         size: editedSize,
                         extraStrOne: editingItem.extraStrOne,
                         extraStrTwo: editingItem.extraStrTwo,
                         isActive: editingItem.isActive,
                         extraIntOne: editingItem.extraIntOne,
                         extraIntTwo: editingItem.extraIntTwo,
                         lastPurchase: editingItem.lastPurchase, // keep original
                         lastUpdated: nowString, // update to now
                         isHot: editedIsHot
                     )
                     pantryAPIService.updatePantryItem(updatedItem) { result in
                         switch result {
                         case .success:
                             pantryAPIService.fetchPantryItems()
                             self.editingItem = nil
                         case .failure(let error):
                             errorMessage = ErrorMessage(message: error.localizedDescription)
                         }
                     }
                 })
             }
         }
         .alert(item: $errorMessage) { msg in
             Alert(title: Text("Error"), message: Text(msg.message), dismissButton: .default(Text("OK")))
         }
         .alert(isPresented: $showDeleteAlert) {
             Alert(
                 title: Text("Delete Item"),
                 message: Text("Are you sure you want to delete this item?"),
                 primaryButton: .destructive(Text("Delete")) {
                     if let item = itemToDelete {
                         pantryAPIService.deletePantryItem(id: item.id) { result in
                             switch result {
                             case .success:
                                 itemToDelete = nil
                             case .failure(let error):
                                 errorMessage = ErrorMessage(message: error.localizedDescription)
                             }
                         }
                     }
                 },
                 secondaryButton: .cancel {
                     itemToDelete = nil
                 }
             )
         }
    }

    // New detail view for showing full item information
    private struct ItemDetailView: View {
        let item: PantryItem
        @ObservedObject var pantryAPIService: PantryAPIService

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name)
                        .font(.largeTitle)
                        .bold()
                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Location:")
                            .bold()
                        Text(item.location)
                    }
                    HStack {
                        Text("Size:")
                            .bold()
                        Text(item.size)
                    }
                    HStack {
                        Text("Quantity:")
                            .bold()
                        Text("\(item.extraIntOne)")
                    }
                    HStack {
                        Text("Barcode:")
                            .bold()
                        Text(item.extraStrOne)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    HStack {
                        Text("Hot:")
                            .bold()
                        Text(item.isHot ? "Yes" : "No")
                    }
                    HStack {
                        Text("Last Updated:")
                            .bold()
                        Text(item.lastUpdated)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Compact row view that mirrors the ItemDetailView fields but in a condensed layout
    private struct ItemRowView: View {
        let item: PantryItem

        var body: some View {
            // Use the same content as ItemDetailView's inner VStack so the row matches detail layout
            VStack(alignment: .leading, spacing: 12) {
                Text(item.name)
                    .font(.largeTitle)
                    .bold()

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Location:")
                        .bold()
                    Text(item.location)
                }

                HStack {
                    Text("Size:")
                        .bold()
                    Text(item.size)
                }

                HStack {
                    Text("Quantity:")
                        .bold()
                    Text("\(item.extraIntOne)")
                }

                HStack {
                    Text("Barcode:")
                        .bold()
                    Text(item.extraStrOne)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                HStack {
                    Text("Hot:")
                        .bold()
                    Text(item.isHot ? "Yes" : "No")
                }

                HStack {
                    Text("Last Updated:")
                        .bold()
                    Text(item.lastUpdated)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

}

#if DEBUG
struct ScannedItemsList_Previews: PreviewProvider {
    static var previews: some View {
        // Create a preview service and populate with sample items
        let previewService = PantryAPIService()
        previewService.items = [
            PantryItem(
                id: 1,
                name: "Canned Carrots",
                description: "Whole peeled carrots",
                location: "Pantry Shelf",
                imageUrl: "",
                imageName: "",
                size: "400g",
                extraStrOne: "0123456789012",
                extraStrTwo: "",
                isActive: 1,
                extraIntOne: 2,
                extraIntTwo: 0,
                lastPurchase: "2025-12-01",
                lastUpdated: "2025-12-10T12:34:56.000",
                isHot: false
            ),
            PantryItem(
                id: 2,
                name: "Canned Tomatoes",
                description: "Whole peeled tomatoes",
                location: "Pantry Shelf",
                imageUrl: "",
                imageName: "",
                size: "400g",
                extraStrOne: "0123456789012",
                extraStrTwo: "",
                isActive: 1,
                extraIntOne: 2,
                extraIntTwo: 0,
                lastPurchase: "2025-12-01",
                lastUpdated: "2025-12-10T12:34:56.000",
                isHot: false
            ),
            PantryItem(
                id: 3,
                name: "Olive Oil",
                description: "Extra virgin",
                location: "Top Shelf",
                imageUrl: "",
                imageName: "",
                size: "750ml",
                extraStrOne: "0987654321098",
                extraStrTwo: "",
                isActive: 1,
                extraIntOne: 1,
                extraIntTwo: 0,
                lastPurchase: "2026-01-15",
                lastUpdated: "2026-01-20T09:00:00.000",
                isHot: false
            )
        ]

        return NavigationStack {
            ScannedItemsList(pantryAPIService: previewService)
        }
        .previewDisplayName("Pantry - Name list")
    }
}
#endif
