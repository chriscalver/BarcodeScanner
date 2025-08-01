import SwiftUI
import AVFoundation
import Vision


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
                        self.parent.isScanning = false
                    }
                }
            } catch {
                print("Barcode detection failed: \(error)")
            }
        }
    }
}
