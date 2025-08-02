import SwiftUI
import AVFoundation
import Vision
import AudioToolbox

enum NavigationTarget: Hashable, Identifiable {
    case scannedItems
    var id: Self { self }
}

struct ContentView: View {
    @State private var scannedItems: [ScannedItem] = ScannedItem.loadAll()
    @State private var pendingCode: String? = nil
    @State private var isNaming: Bool = false
    @State private var newName: String = ""
    @State private var newQuantity: String = ""
    @State private var isScanning: Bool = false
    @State private var navigationTarget: NavigationTarget?
    @State private var showCheckmark: Bool = false
    @State private var isLoading: Bool = true
    @State private var showDuplicateAlert: Bool = false

    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading PantryPro...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.primary)
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isLoading = false
                        }
                    }
                }
            } else {
                NavigationStack {
                    ZStack {
                        if isScanning {
                            ScannerView(
                                scannedItems: $scannedItems,
                                isScanning: $isScanning,
                                pendingCode: Binding(
                                    get: { pendingCode },
                                    set: { code in
                                        if let code = code {
                                            if scannedItems.contains(where: { $0.code == code }) {
                                                isScanning = false
                                                isNaming = false
                                                pendingCode = nil
                                                // Use a slightly longer delay to ensure the scanner sheet is fully dismissed
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                    showDuplicateAlert = true
                                                }
                                            } else {
                                                pendingCode = code
                                                isNaming = true
                                            }
                                        }
                                    }
                                ),
                                isNaming: $isNaming
                            )
                            .edgesIgnoringSafeArea(.all)
                        }

                        VStack(spacing: 16) {
                            Spacer()
                            Text("Leesy's")
                                .font(.system(size: 58, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            ZStack(alignment: .bottomTrailing) {
                                Image(systemName: "p.square.fill")
                                    .font(.system(size: 128))
                                    .foregroundColor(.blue)
                                if showCheckmark {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                        .offset(x: -7, y: -90)
                                        .transition(.opacity)
                                }
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation {
                                        showCheckmark = true
                                    }
                                }
                            }
                            Text("PantryPro")
                                .font(.system(size: 32))
                                .bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Check Pantry Now") {
                                navigationTarget = .scannedItems
                            }
                            .padding()
                            Button(isScanning ? "Stop Scan" : "Start Scan") {
                                if isScanning {
                                    isScanning = false
                                } else {
                                    pendingCode = nil
                                    isNaming = false
                                    isScanning = true
                                }
                            }
                            .padding()
                            .background(isScanning ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding()
                    }
                    .sheet(isPresented: $isNaming) {
                        NameItemSheet(
                            newName: $newName,
                            newQuantity: $newQuantity,
                            onSave: {
                                if let code = pendingCode, let qty = Int(newQuantity) {
                                    scannedItems.append(ScannedItem(code: code, name: newName, quantity: qty))
                                    navigationTarget = .scannedItems
                                }
                                newName = ""
                                newQuantity = ""
                                pendingCode = nil
                                isNaming = false
                            },
                            onCancel: {
                                newName = ""
                                newQuantity = ""
                                pendingCode = nil
                                isNaming = false
                            }
                        )
                    }
                    .navigationDestination(item: $navigationTarget) { target in
                        switch target {
                        case .scannedItems:
                            ScannedItemsList(items: $scannedItems)
                        }
                    }
                }
                .onChange(of: scannedItems) { newItems in
                    ScannedItem.saveAll(newItems)
                }
            }
        }
        .alert("Duplicate Barcode", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This barcode has already been added.")
        }
    }
}
