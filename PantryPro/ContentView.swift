import SwiftUI
import AVFoundation
import Vision
import AudioToolbox

// Add this import for the API service
import Combine

enum NavigationTarget: Hashable, Identifiable {
    case scannedItems
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
    @State private var showAddErrorAlert: Bool = false
    @State private var addErrorMessage: String = ""
    @State private var showDuplicateAlert: Bool = false // State for duplicate alert
    @State private var allBarcodes: [String] = [] // Store barcodes in state
    @State private var isReadyToScan: Bool = false

    @StateObject private var pantryAPIService = PantryAPIService() // Use API service
    @State private var lastDuplicateCode: String? = nil // Track last duplicate code

    @AppStorage("userName") private var userName: String = ""
    @State private var showNamePrompt: Bool = false
    @State private var tempName: String = ""

    // Barcode normalization helper
    private func normalizeBarcode(_ code: String?) -> String {
        return code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }

    // Helper to update barcodes from items
    private func updateBarcodes() {
        var barcodes: [String] = []
        for item in pantryAPIService.items {
            let code = normalizeBarcode(item.extraStrOne)
            if !code.isEmpty {
                barcodes.append(code)
            }
        }
        print("[DEBUG] Updated allBarcodes: \(barcodes)")
        allBarcodes = barcodes
    }

    // Call updateBarcodes right before scanning starts
    private func startScanning() {
        isLoading = true
        isReadyToScan = false
        pantryAPIService.fetchPantryItems()
        // Wait for pantryAPIService.items to update, then updateBarcodes and enable scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            updateBarcodes()
            print("[DEBUG] Barcodes at scan start: \(allBarcodes)")
            pendingCode = nil
            isNaming = false
            isScanning = true
            isLoading = false
            isReadyToScan = true
        }
    }

    // Refactored: handle pending code logic in a separate function
    private func handlePendingCode(_ code: String?) {
        if showDuplicateAlert || isNaming || isLoading || !isReadyToScan {
            print("[DEBUG] handlePendingCode: Ignored because alert, naming sheet, loading, or not ready to scan")
            return
        }
        print("[DEBUG] handlePendingCode called with code: \(String(describing: code))")
        let normalized = normalizeBarcode(code)
        print("[DEBUG] allBarcodes at duplicate check: \(allBarcodes)")
        if !normalized.isEmpty {
            print("[DEBUG] Normalized code: \(normalized)")
            if allBarcodes.contains(normalized) {
                print("[DEBUG] Duplicate code detected: \(normalized)")
                isScanning = false
                isNaming = false
                pendingCode = nil
                lastDuplicateCode = normalized
                showAddErrorAlert = false
                showDuplicateAlert = true // Set immediately, no delay
                return
            }
            print("[DEBUG] New code, presenting naming sheet: \(normalized)")
            pendingCode = normalized
            isNaming = true
            print("[DEBUG] Naming sheet should now be visible")
        } else {
            print("[DEBUG] Invalid or empty code scanned.")
        }
    }

    // MARK: - Logo With Checkmark View
    private var logoWithCheckmark: AnyView {
        AnyView(LogoWithCheckmarkView(showCheckmark: $showCheckmark))
    }

    // MARK: - Main Content View
    private var mainContent: some View {
        VStack(spacing: 16) {
            Spacer()
            HStack(spacing: 8) {
                Text(userName)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Button(action: {
                    tempName = userName
                    showNamePrompt = true
                }) {
                    Image(systemName: "pencil")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
                .accessibilityLabel("Edit Name")
            }
            logoWithCheckmark
            Text("PantryPro")
                .font(.system(size: 32))
                .bold()
                .foregroundColor(.primary)
            barcodesDebugView
            Spacer()
            mainButtons
        }
        .padding()
    }

    private var barcodesDebugView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("All Barcodes (Debug):")
                    .font(.headline)
                if allBarcodes.isEmpty {
                    Text("No barcodes loaded.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 8)
                } else {
                    ForEach(allBarcodes, id: \.self) { barcode in
                        Text(barcode)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 120)
    }

    private var mainButtons: some View {
        VStack(spacing: 8) {
            Button("Check Pantry Now") {
                navigationTarget = .scannedItems
            }
            .padding()
            Button(isScanning ? "Stop Scan" : "Start Scan") {
                if (isScanning) {
                    isScanning = false
                } else {
                    startScanning()
                }
            }
            .padding()
            .background(isScanning ? Color.red : Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            // Removed "View Online Pantry" button
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
                    pantryAPIService.fetchPantryItems()
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
                                )
                            )
                            .edgesIgnoringSafeArea(.all)
                        }
                        mainContent
                    }
                    .navigationDestination(item: $navigationTarget) { target in
                        navigationDestinationView(for: target)
                    }
                }
                .sheet(isPresented: $isNaming) {
                    NameItemSheet(
                        newName: $newName,
                        newDescription: $newDescription,
                        newQuantity: $newQuantity,
                        newSize: $newSize,
                        newLocation: $newLocation,
                        newIsHot: $newIsHot,
                        onSave: {
                            handleNameItemSave()
                        },
                        onCancel: {
                            newName = ""
                            newDescription = ""
                            newQuantity = ""
                            newSize = ""
                            newLocation = ""
                            newIsHot = false
                            pendingCode = nil
                            isNaming = false
                        }
                    )
                    .presentationDetents([.large])
                }
                .onChange(of: scannedItems) { newItems in
                    ScannedItem.saveAll(newItems)
                }
                .onAppear {
                    pantryAPIService.fetchPantryItems()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        updateBarcodes()
                    }
                    if userName.isEmpty {
                        showNamePrompt = true
                    }
                }
                .onChange(of: pantryAPIService.items) { _ in
                    updateBarcodes()
                }
                .alert("Enter your name", isPresented: $showNamePrompt, actions: {
                    TextField("Name", text: $tempName)
                    Button("OK") {
                        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            userName = trimmed
                            showNamePrompt = false
                        }
                    }
                }, message: {
                    Text("Please enter your name to personalize your PantryPro experience.")
                })
            }
        }
        .alert("Error Adding Item", isPresented: $showAddErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addErrorMessage)
        }
        .alert("Duplicate Barcode", isPresented: $showDuplicateAlert) {
            Button("View Item") {
                print("[DEBUG] Duplicate alert button tapped")
                navigationTarget = .scannedItems
                showDuplicateAlert = false
                print("[DEBUG] Duplicate alert message shown")
            }
            Button("OK", role: .cancel) {
                print("[DEBUG] Duplicate alert dismissed")
                showDuplicateAlert = false
                print("[DEBUG] Duplicate alert message shown")
            }
        } message: {
            Text("This barcode has already been added.")
        }
    }

    private func handleNameItemSave() {
        guard let qty = Int(newQuantity) else { return }
        let barcodeToSend = normalizeBarcode(pendingCode)
        print("[DEBUG] pendingCode: \(String(describing: pendingCode)), barcodeToSend: \(barcodeToSend)")
        isLoading = true // Disable scanning while updating
        pantryAPIService.addPantryItem(
            name: newName,
            description: newDescription,
            quantity: qty,
            size: newSize,
            location: newLocation,
            isHot: newIsHot,
            extraStrOne: barcodeToSend
        ) { result in
            switch result {
            case .success:
                let newItem = ScannedItem(
                    code: barcodeToSend,
                    name: newName,
                    description: newDescription,
                    quantity: qty,
                    size: newSize,
                    location: newLocation,
                    isHot: newIsHot
                )
                scannedItems.append(newItem)
                // Do not append to allBarcodes directly; updateBarcodes will be called after fetch
                pantryAPIService.fetchPantryItems()
                newName = ""
                newDescription = ""
                newQuantity = ""
                newSize = ""
                newLocation = ""
                newIsHot = false
                pendingCode = nil
                isNaming = false
            case .failure(let error):
                print("[DEBUG] addPantryItem failed: \(error.localizedDescription)")
                if error.localizedDescription.contains("barcode already exists") || error.localizedDescription.contains("Duplicate barcode") {
                    // Backend duplicate error
                    showDuplicateAlert = true
                    isNaming = false
                    pendingCode = nil
                } else {
                    addErrorMessage = error.localizedDescription
                    showAddErrorAlert = true
                }
            }
            isLoading = false // Re-enable scanning
        }
    }

    private func navigationDestinationView(for target: NavigationTarget) -> AnyView {
        switch target {
        case .scannedItems:
            return AnyView(ScannedItemsList(pantryAPIService: pantryAPIService))
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

// MARK: - Subviews for Type-Checking

private struct LogoWithCheckmarkView: View {
    @Binding var showCheckmark: Bool
    var body: some View {
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
    }
}
