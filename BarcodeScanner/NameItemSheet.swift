import SwiftUI

struct NameItemSheet: View {
    @Binding var newName: String
    @Binding var newQuantity: String
    let onSave: () -> Void
    let onCancel: () -> Void // Add this closure

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "p.square.fill")
                .font(.system(size: 128))
                .foregroundColor(.blue)
            Text("PantryPro")
                .font(.system(size: 38))
                .bold()
                .foregroundColor(.primary)
                .padding()
            Text("Name this new item")
                .font(.headline)
                .padding(.bottom, 8)
            TextField("Item name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            TextField("Quantity", text: $newQuantity)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            HStack {
                Button("Cancel", action: onCancel)
                    .padding()
                Button("Save", action: onSave)
                    .disabled(newName.isEmpty || Int(newQuantity) == nil)
                    .padding()
            }
        }
        .padding()
    }
}

#Preview {
    NameItemSheet(
        newName: .constant("Item name"),
        newQuantity: .constant("qty"),
        onSave: { print("Saved!") },
        onCancel: { print("Cancelled!") }
    )
}
