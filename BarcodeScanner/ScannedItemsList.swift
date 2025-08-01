import SwiftUI

struct ScannedItemsList: View {
    @Binding var items: [ScannedItem]
    @State private var editingItem: ScannedItem?
    @State private var editedName: String = ""
    @State private var editedQuantity: String = ""

    var body: some View {
        VStack(spacing: 1) {
            
            Image(systemName: "p.square.fill")
                .font(.system(size: 128))
                .foregroundColor(.blue)
                .padding(.top, 16)
            Text("PantryPro")
//                        .font(.largeTitle)
                .font(.system(size: 38))
                .bold()
                .foregroundColor(.primary)
//                .padding()
            
            
            Text("Current Items")
                .font(.title2)
//                .padding(.bottom, 8)
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
//                            .font(.headline)
//                        Text("BarCode: \(item.code)")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Qty: \(item.quantity)")
//                        .bold()
                    Button("Edit") {
                        editingItem = item
                        editedName = item.name
                        editedQuantity = "\(item.quantity)"
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 1)
            }
            .onDelete { indexSet in
                items.remove(atOffsets: indexSet)
            }
        }
        .sheet(item: $editingItem) { item in
            VStack(spacing: 16) {
                Text("Edit Item")
                    .font(.title2)
                    .bold()
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                TextField("Quantity", text: $editedQuantity)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
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
            .padding()
        }
    }
} 

#Preview {
    // For preview, use .constant to provide a binding
    ScannedItemsList(items: .constant([
        ScannedItem(code: "123456", name: "Sample Item", quantity: 2),
        ScannedItem(code: "789012", name: "Another Item", quantity: 1)
    ]))
}
