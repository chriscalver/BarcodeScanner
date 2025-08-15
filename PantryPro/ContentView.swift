import SwiftUI
import AVFoundation
import Vision
import AudioToolbox

// Add this import for the API service
import Combine

enum NavigationTarget: Hashable, Identifiable {
    case scannedItems
    case apiPantry
    var id: Self { self }
}

struct ContentView: View {
    @State private var scannedItems: [ScannedItem] = ScannedItem.loadAll()
    @State private var pendingCode: String? = nil
    @State private var isNaming: Bool = false
    @State private var newName: String = ""
    @State private var newDescription: String = "" // Added for description binding
    @State private var newQuantity: String = ""
    @State private var newSize: String = "" // Added for size binding
    @State private var newLocation: String = "" // Added for location binding
    @State private var newIsHot: Bool = false // Added for isHot binding
    @State private var isScanning: Bool = false
    @State private var navigationTarget: NavigationTarget?
    @State private var showCheckmark: Bool = false
    @State private var isLoading: Bool = true
    @State private var showDuplicateAlert: Bool = false
    @State private var lastDuplicateCode: String? = nil // Track last duplicate code
    
    // Refactored: handle pending code logic in a separate function
    private func handlePendingCode(_ code: String?) {
        if let code = code {
            if scannedItems.contains(where: { $0.code == code }) {
                isScanning = false
                isNaming = false
                pendingCode = nil
                lastDuplicateCode = code // Store duplicate code
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
                                    set: { handlePendingCode($0) }
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
                                        .offset(x: -9, y: -90)
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
                            Button("View Online Pantry") {
                                navigationTarget = nil // Reset to avoid stale navigation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    navigationTarget = .apiPantry
                                }
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding()
                    }
                    .sheet(isPresented: $isNaming) {
                        NameItemSheet(
                            newName: $newName,
                            newDescription: $newDescription, // Pass the binding
                            newQuantity: $newQuantity,
                            newSize: $newSize,
                            newLocation: $newLocation,
                            newIsHot: $newIsHot, // Pass the binding
                            onSave: {
                                if let code = pendingCode, let qty = Int(newQuantity) {
                                    scannedItems.append(ScannedItem(code: code, name: newName, description: newDescription, quantity: qty, size: newSize, location: newLocation, isHot: newIsHot))
                                    navigationTarget = .scannedItems
                                }
                                newName = ""
                                newDescription = "" // Clear on save
                                newQuantity = ""
                                newSize = ""
                                newLocation = ""
                                newIsHot = false // Clear on save
                                pendingCode = nil
                                isNaming = false
                            },
                            onCancel: {
                                newName = ""
                                newDescription = "" // Clear on cancel
                                newQuantity = ""
                                newSize = ""
                                newLocation = ""
                                newIsHot = false // Clear on cancel
                                pendingCode = nil
                                isNaming = false
                            }
                        )
                    }
                    .navigationDestination(item: $navigationTarget) { target in
                        switch target {
                        case .scannedItems:
                            ScannedItemsList(items: $scannedItems, highlightedCode: lastDuplicateCode)
                        case .apiPantry:
                            PantryListView()
                        }
                    }
                }
                .onChange(of: scannedItems) { newItems in
                    ScannedItem.saveAll(newItems)
                }
            }
        }
        .alert("Duplicate Barcode", isPresented: $showDuplicateAlert) {
            Button("View Item") {
                navigationTarget = .scannedItems
                showDuplicateAlert = false
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("This barcode has already been added.")
        }
    }
}

struct PantryListView: View {
    @StateObject private var apiService = PantryAPIService()
    @State private var sendResult: String? = nil
    @State private var isSending: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    isSending = true
                    apiService.sendMockPantryItem { result in
                        isSending = false
                        switch result {
                        case .success:
                            sendResult = "Mock item sent successfully!"
                            apiService.fetchPantryItems() // Refresh list
                        case .failure(let error):
                            sendResult = "Failed to send: \(error.localizedDescription)"
                        }
                    }
                }) {
                    if isSending {
                        ProgressView()
                    } else {
                        Text("Send Mock Item")
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .clipShape(Capsule())
                if let sendResult = sendResult {
                    Text(sendResult)
                        .foregroundColor(sendResult.contains("success") ? .green : .red)
                        .padding(.bottom)
                }
                List(apiService.items) { item in
                    VStack(alignment: .leading) {
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
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Pantry API Items")
                .onAppear {
                    apiService.fetchPantryItems()
                }
                .overlay(
                    Group {
                        if let error = apiService.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }, alignment: .bottom
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
