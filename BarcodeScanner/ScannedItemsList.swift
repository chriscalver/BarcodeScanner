import SwiftUI

struct ScannedItemsList: View {
    @Binding var items: [ScannedItem]
    @State private var editingItem: ScannedItem?
    @State private var editedName: String = ""
    @State private var editedQuantity: String = ""
    @State private var deleteIndexSet: IndexSet?
    @State private var showDeleteAlert = false

    var body: some View {
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
                        editingItem = item
                        editedName = item.name
                        editedQuantity = "\(item.quantity)"
                    }
                    .buttonStyle(.bordered)
                }
            }
            .onDelete { indexSet in
                deleteIndexSet = indexSet
                showDeleteAlert = true
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
        .sheet(item: $editingItem) { item in
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
                TextField("Name", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
                TextField("Quantity", text: $editedQuantity)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
                HStack(spacing: 1){
                    Button("Save") {
                        if let idx = items.firstIndex(where: { $0.id == item.id }),
                           let qty = Int(editedQuantity) {
                            items[idx].name = editedName
                            items[idx].quantity = qty
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
