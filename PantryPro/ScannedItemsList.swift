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
        ScrollViewReader { proxy in
            VStack(spacing: 1) {
                Image(systemName: "p.square.fill")
                    .font(.system(size: 128))
                    .foregroundColor(.blue)
                    .padding(.top, 16)
                Text("PantryPro")
                    .font(.system(size: 38))
                    .bold()
                    .foregroundColor(.primary)
                Text("Current Items")
                    .font(.title2)
                if items.isEmpty {
                    Text("No items in pantry.")
                        .foregroundColor(.secondary)
                }
            }
            List {
                ForEach(items) { item in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) { // Left align horizontally
                            Text(item.name)
                                .font(.headline)
                            Text(item.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("Location: \(item.location)")
                                if item.isHot {
                                    Image(systemName: "flame.fill").foregroundColor(.red)
                                }
                            }
                            Text("Barcode: \(item.extraStrOne)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(spacing: 10) {
                            Spacer()
                            Button(action: {
                                editedName = item.name
                                editedDescription = item.description
                                editedLocation = item.location
                                editedSize = item.size
                                editedIsHot = item.isHot
                                editingItem = item
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Button(action: {
                                itemToDelete = item
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
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
    }
}
