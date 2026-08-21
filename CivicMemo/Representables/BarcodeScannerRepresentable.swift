import AVFoundation
import SwiftUI
import UIKit
import Vision

struct BarcodeScannerRepresentable: UIViewRepresentable {
  var onCode: (String) -> Void

  func makeUIView(context: Context) -> ScannerCanvas {
    let canvas = ScannerCanvas()
    canvas.engine.onCode = onCode
    canvas.startSession()
    return canvas
  }

  func updateUIView(_ uiView: ScannerCanvas, context: Context) {
    uiView.engine.onCode = onCode
  }

  static func dismantleUIView(_ uiView: ScannerCanvas, coordinator: ()) {
    uiView.stopSession()
  }
}

final class ScannerCanvas: UIView {
  let engine = ScannerEngine()
  private let preview = AVCaptureVideoPreviewLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor(red: 0.106, green: 0.227, blue: 0.420, alpha: 1)
    preview.videoGravity = .resizeAspectFill
    layer.insertSublayer(preview, at: 0)
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    preview.frame = bounds
  }

  func startSession() {
    engine.attach(preview)
    engine.start()
  }

  func stopSession() {
    engine.stop()
  }
}

final class ScannerEngine: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
  var onCode: ((String) -> Void)?
  private let session = AVCaptureSession()
  private let output = AVCaptureVideoDataOutput()
  private let sessionQueue = DispatchQueue(label: "civicmemo.barcode.session")
  private let visionQueue = DispatchQueue(label: "civicmemo.barcode.vision")
  private var lastEmit: TimeInterval = 0
  private var didConfigure = false

  func attach(_ preview: AVCaptureVideoPreviewLayer) {
    preview.session = session
  }

  func start() {
    sessionQueue.async { [weak self] in
      self?.configureIfNeeded()
      self?.session.startRunning()
    }
  }

  func stop() {
    sessionQueue.async { [weak self] in
      self?.session.stopRunning()
    }
  }

  private func configureIfNeeded() {
    guard !didConfigure else { return }
    didConfigure = true
    session.beginConfiguration()
    session.sessionPreset = .high
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input)
    else {
      session.commitConfiguration()
      return
    }
    session.addInput(input)
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(self, queue: visionQueue)
    if session.canAddOutput(output) {
      session.addOutput(output)
    }
    session.commitConfiguration()
  }

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    let now = Date().timeIntervalSince1970
    guard now - lastEmit > 0.7 else { return }
    guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let request = VNDetectBarcodesRequest { [weak self] request, _ in
      guard
        let observations = request.results as? [VNBarcodeObservation],
        let payload = observations.compactMap(\.payloadStringValue).first
      else { return }
      self?.lastEmit = now
      DispatchQueue.main.async {
        self?.onCode?(payload)
      }
    }
    request.symbologies = [.ean8, .ean13, .upce, .code128, .qr, .itf14]
    let handler = VNImageRequestHandler(cvPixelBuffer: pixel, orientation: .right)
    try? handler.perform([request])
  }
}
