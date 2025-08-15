import SwiftUI

struct NameItemSheet: View {
    @Binding var newName: String
    @Binding var newDescription: String // Added binding for description
    @Binding var newQuantity: String
    @Binding var newSize: String // Added binding for size
    @Binding var newLocation: String // Added binding for location
    @Binding var newIsHot: Bool // Added binding for isHot
    let onSave: () -> Void
    let onCancel: () -> Void // Add this closure

    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case name, description, quantity, size, location
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 2) {
                    Image(systemName: "p.square.fill")
                        .font(.system(size: 128))
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    Text("PantryPro")
                        .font(.system(size: 38))
                        .bold()
                        .foregroundColor(.primary)
                        .padding(.bottom, 2)
                    Text("Name this new item")
                        .font(.headline)
                        .padding(.bottom, 8)
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Details")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .padding(.top, 8)
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                TextField("Item name", text: $newName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: .name)
                            }
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.teal)
                                TextField("Description", text: $newDescription)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: .description)
                            }
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.purple)
                                TextField("Quantity", text: $newQuantity)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: .quantity)
                            }
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(.orange)
                                TextField("Size", text: $newSize)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: .size)
                            }
                            HStack {
                                Image(systemName: "map")
                                    .foregroundColor(.green)
                                TextField("Location", text: $newLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($focusedField, equals: .location)
                            }
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.red)
                                Toggle("Is Hot", isOn: $newIsHot)
                                    .labelsHidden()
                            }
                        }
                        .padding(18)
                    }
                    .padding(.vertical, 8)
                    Spacer(minLength: 40)
                }
                .frame(minHeight: UIScreen.main.bounds.height * 0.9)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedField) { field in
                if field != nil {
                    withAnimation {
                        proxy.scrollTo("saveButton", anchor: .bottom)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    Button("Save", action: onSave)
                        .disabled(newName.isEmpty || Int(newQuantity) == nil)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background((newName.isEmpty || Int(newQuantity) == nil) ? Color(.systemGray4) : Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .id("saveButton")
                }
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    NameItemSheet(
        newName: .constant("Item name"),
        newDescription: .constant("desc"), // Added preview binding
        newQuantity: .constant("qty"),
        newSize: .constant("size"),
        newLocation: .constant("location"),
        newIsHot: .constant(false), // Added preview binding
        onSave: { print("Saved!") },
        onCancel: { print("Cancelled!") }
    )
}
