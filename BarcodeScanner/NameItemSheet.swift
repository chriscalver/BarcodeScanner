import SwiftUI

struct NameItemSheet: View {
    @Binding var newName: String
    @Binding var newQuantity: String
    let onSave: () -> Void

    var body: some View {
        VStack {
            Text("Name this item")
            TextField("Item name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
             
            TextField("Quantity", text: $newQuantity)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Save", action: onSave)
                .disabled(newName.isEmpty || Int(newQuantity) == nil)
                .padding()
        }
        .padding()
    }
}

#Preview {
    NameItemSheet(
        newName: .constant("Sample Item"),
        newQuantity: .constant("1"),
        onSave: { print("Saved!") }
    )
}
