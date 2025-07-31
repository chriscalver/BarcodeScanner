
import SwiftUI
import AVFoundation
import Vision

struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let code: String
    var name: String
    var quantity: Int
}


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
                    VStack {
                        Text("Name this item")
                        TextField("Item name", text: $newName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Quantity", text: $newQuantity)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Save") {
                            if let code = pendingCode, let qty = Int(newQuantity) {
                                scannedItems.append(ScannedItem(code: code, name: newName, quantity: qty))
                            }
                            newName = ""
                            newQuantity = ""
                            pendingCode = nil
                            isNaming = false
                        }
                        .disabled(newName.isEmpty || Int(newQuantity) == nil)
                        .padding()
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedItems: [ScannedItem]
    @Binding var isScanning: Bool
    @Binding var pendingCode: String?
        @Binding var isNaming: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.makeViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.updateSession(isScanning: isScanning)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: ScannerView
        private let captureSession = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?

        init(parent: ScannerView) {
            self.parent = parent
        }

        func makeViewController() -> UIViewController {
            let viewController = UIViewController()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  captureSession.canAddInput(videoInput) else { return viewController }

            captureSession.addInput(videoInput)

            let videoOutput = AVCaptureVideoDataOutput()
            if captureSession.canAddOutput(videoOutput) {
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                captureSession.addOutput(videoOutput)
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = viewController.view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            viewController.view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            return viewController
        }

        func updateSession(isScanning: Bool) {
            DispatchQueue.global(qos: .userInitiated).async {
                if isScanning && !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                } else if !isScanning && self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                }
            }
        }
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            detectBarcode(in: pixelBuffer)
        }

        
        func detectBarcode(in pixelBuffer: CVPixelBuffer) {
            let request = VNDetectBarcodesRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

            do {
                try handler.perform([request])
                if let results = request.results, let payload = results.first?.payloadStringValue {
                    DispatchQueue.main.async {
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                        self.parent.pendingCode = payload
                        self.parent.isNaming = true
                        
                        self.parent.isScanning = false // Stop scan after detection
                    }
                }
            } catch {
                print("Barcode detection failed: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
