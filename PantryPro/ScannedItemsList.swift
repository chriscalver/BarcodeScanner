import SwiftUI

struct ScannedItemsList: View {
    @Binding var items: [ScannedItem]
    var highlightedCode: String? = nil // Accept highlightedCode
    @State private var editingItem: ScannedItem?
    @State private var editedName: String = ""
    @State private var editedDescription: String = "" // Added for description editing
    @State private var editedQuantity: String = ""
    @State private var editedSize: String = "" // Added for size editing
    @State private var editedLocation: String = "" // Added for location editing
    @State private var editedIsHot: Bool = false // Added for isHot editing
    @State private var deleteIndexSet: IndexSet?
    @State private var showDeleteAlert = false

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
                    Text("No items scanned yet.")
                        .foregroundColor(.secondary)
                }
            }
            List {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                        }
                        Spacer()
                        Text("Qty: \(item.quantity)")
                        Button("Edit") {
                            editedName = item.name
                            editedDescription = item.description
                            editedQuantity = "\(item.quantity)"
                            editedSize = item.size
                            editedLocation = item.location
                            editedIsHot = item.isHot
                            editingItem = item
                        }
                        .buttonStyle(.bordered)
                        Button("Delete") {
                            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                deleteIndexSet = IndexSet(integer: idx)
                                showDeleteAlert = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .id(item.code) // Set id for scroll
                    .background(
                        (highlightedCode != nil && item.code == highlightedCode) ? Color.yellow.opacity(0.3) : Color.clear
                    )
                }
                .onDelete { indexSet in
                    deleteIndexSet = indexSet
                    showDeleteAlert = true
                }
            }
            .onAppear {
                if let code = highlightedCode, let match = items.first(where: { $0.code == code }) {
                    withAnimation {
                        proxy.scrollTo(match.code, anchor: .center)
                    }
                }
            }
            .alert("Delete Item?", isPresented: $showDeleteAlert, actions: {
                Button("Delete", role: .destructive) {
                    if let indexSet = deleteIndexSet {
                        items.remove(atOffsets: indexSet)
                    }
                    deleteIndexSet = nil
                }
                Button("Cancel", role: .cancel) {
                    deleteIndexSet = nil
                }
            }, message: {
                Text("Are you sure you want to delete this item?")
            })
            .sheet(item: $editingItem, onDismiss: {
                editedName = ""
                editedDescription = ""
                editedQuantity = ""
                editedSize = ""
                editedLocation = ""
                editedIsHot = false
            }) { item in
                VStack(spacing: 6) {
                    Image(systemName: "p.square.fill")
                        .font(.system(size: 128))
                        .foregroundColor(.blue)
                        .padding(.top, 16)
                    Text("PantryPro")
                        .font(.system(size: 38))
                        .bold()
                        .foregroundColor(.primary)
                    Text("Edit Item")
                        .font(.title2)
                        .bold()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Name", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Description", text: $editedDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                        Text("Quantity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Quantity", text: $editedQuantity)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                        Text("Size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Size", text: $editedSize)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                        Text("Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Location", text: $editedLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                        Toggle("Is Hot", isOn: $editedIsHot)
                            .frame(width: 250)
                            .padding(.vertical, 8)
                    }
                    HStack(spacing: 1){
                        Button("Save") {
                            if let idx = items.firstIndex(where: { $0.id == item.id }),
                               let qty = Int(editedQuantity) {
                                items[idx].name = editedName
                                items[idx].description = editedDescription
                                items[idx].quantity = qty
                                items[idx].size = editedSize
                                items[idx].location = editedLocation
                                items[idx].isHot = editedIsHot
                            }
                            editingItem = nil
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Cancel") {
                            editingItem = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
    }
}
