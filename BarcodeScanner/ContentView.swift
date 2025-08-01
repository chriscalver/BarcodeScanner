import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @State private var scannedItems: [ScannedItem] = []
    @State private var pendingCode: String? = nil
    @State private var isNaming: Bool = false
    @State private var newName: String = ""
    @State private var newQuantity: String = ""
    @State private var isScanning: Bool = false
    
    
    var body: some View {
        ZStack() {
            if isScanning {
                ScannerView(
                    scannedItems: $scannedItems,
                    isScanning: $isScanning,
                    pendingCode: $pendingCode,
                    isNaming: $isNaming
                )        .edgesIgnoringSafeArea(.all)
            }
            VStack(spacing: 16) {
                Text("Calver Scanner")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding()
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 94))
                    .foregroundColor(.blue)
//                    .padding()
                
                Spacer()
                    
                Text("Scan a barcode")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button(isScanning ? "Stop Scan" : "Start Scan") {
                    isScanning.toggle()
                }
                .padding()
                .background(isScanning ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(scannedItems) { item in
                        Text("\(item.name) (\(item.quantity)): \(item.code)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .sheet(isPresented: $isNaming) {
                    NameItemSheet(
                        newName: $newName,
                        newQuantity: $newQuantity
                    ) {
                        if let code = pendingCode, let qty = Int(newQuantity) {
                            scannedItems.append(ScannedItem(code: code, name: newName, quantity: qty))
                        }
                        newName = ""
                        newQuantity = ""
                        pendingCode = nil
                        isNaming = false
                    }
                }
            }
            .padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
}
