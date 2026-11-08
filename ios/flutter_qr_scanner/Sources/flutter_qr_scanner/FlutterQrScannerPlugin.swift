import Flutter
import UIKit
import AVFoundation

public class FlutterQrScannerPlugin: NSObject, FlutterPlugin {
  private var isScanning = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_qr_scanner", binaryMessenger: registrar.messenger())
    let instance = FlutterQrScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
      startScan(result: result)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startScan(result: @escaping FlutterResult) {
    if isScanning {
      result(FlutterError(code: "ALREADY_SCANNING", message: "A scan is already in progress.", details: nil))
      return
    }

    guard let captureDevice = AVCaptureDevice.default(for: .video) else {
      result(FlutterError(code: "CAMERA_UNAVAILABLE", message: "No camera device is available on this hardware or simulator.", details: nil))
      return
    }

    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch authStatus {
    case .authorized:
      presentScanner(captureDevice: captureDevice, result: result)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.presentScanner(captureDevice: captureDevice, result: result)
          } else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission was denied.", details: nil))
          }
        }
      }
    case .denied, .restricted:
      result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission was denied.", details: nil))
    @unknown default:
      result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission was denied.", details: nil))
    }
  }

  private func presentScanner(captureDevice: AVCaptureDevice, result: @escaping FlutterResult) {
    guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController ??
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find root view controller to present scanner.", details: nil))
      return
    }

    isScanning = true
    var isSubmitted = false

    let safeResult: (Any?) -> Void = { [weak self] value in
      DispatchQueue.main.async {
        if !isSubmitted {
          isSubmitted = true
          self?.isScanning = false
          result(value)
        }
      }
    }

    let scannerVC = QRScannerViewController(captureDevice: captureDevice)
    scannerVC.modalPresentationStyle = .fullScreen
    scannerVC.onScanSuccess = { code in
      safeResult(code)
    }
    scannerVC.onCancel = {
      safeResult(nil)
    }
    scannerVC.onError = { errorMsg in
      safeResult(FlutterError(code: "SCAN_FAILED", message: errorMsg, details: nil))
    }

    // Find the topmost presented controller
    var topController = rootViewController
    while let presented = topController.presentedViewController {
      topController = presented
    }
    topController.present(scannerVC, animated: true, completion: nil)
  }
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  private let captureDevice: AVCaptureDevice
  private var captureSession: AVCaptureSession?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var hasScanned = false

  var onScanSuccess: ((String) -> Void)?
  var onCancel: (() -> Void)?
  var onError: ((String) -> Void)?

  init(captureDevice: AVCaptureDevice) {
    self.captureDevice = captureDevice
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupCamera()
    setupOverlay()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if let session = self?.captureSession, !session.isRunning {
        session.startRunning()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if let session = self?.captureSession, session.isRunning {
        session.stopRunning()
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  private func setupCamera() {
    let session = AVCaptureSession()
    captureSession = session

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      if session.canAddInput(input) {
        session.addInput(input)
      } else {
        onError?("Failed to add video input.")
        dismiss(animated: true)
        return
      }

      let metadataOutput = AVCaptureMetadataOutput()
      if session.canAddOutput(metadataOutput) {
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        var supportedTypes: [AVMetadataObject.ObjectType] = [
          .qr, .ean13, .ean8, .code128, .code39, .code93, .upce, .pdf417, .aztec, .dataMatrix, .itf14
        ]
        if #available(iOS 15.4, *) {
          supportedTypes.append(contentsOf: [.codabar, .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited, .microQR, .microPDF417])
        }
        metadataOutput.metadataObjectTypes = supportedTypes.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }
      } else {
        onError?("Failed to add metadata output.")
        dismiss(animated: true)
        return
      }

      let layer = AVCaptureVideoPreviewLayer(session: session)
      layer.videoGravity = .resizeAspectFill
      layer.frame = view.bounds
      view.layer.addSublayer(layer)
      previewLayer = layer
    } catch {
      onError?(error.localizedDescription)
      dismiss(animated: true)
    }
  }

  private func setupOverlay() {
    // Reticle Frame
    let overlayView = UIView(frame: view.bounds)
    overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)

    let scanSize = min(view.bounds.width, view.bounds.height) * 0.7
    let scanRect = CGRect(
      x: (view.bounds.width - scanSize) / 2,
      y: (view.bounds.height - scanSize) / 2,
      width: scanSize,
      height: scanSize
    )

    let path = UIBezierPath(rect: view.bounds)
    let rectPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 16)
    path.append(rectPath)
    path.usesEvenOddFillRule = true

    let maskLayer = CAShapeLayer()
    maskLayer.path = path.cgPath
    maskLayer.fillRule = .evenOdd
    overlayView.layer.mask = maskLayer
    view.addSubview(overlayView)

    // Border around reticle
    let borderView = UIView(frame: scanRect)
    borderView.layer.borderColor = UIColor.white.cgColor
    borderView.layer.borderWidth = 2
    borderView.layer.cornerRadius = 16
    borderView.isUserInteractionEnabled = false
    view.addSubview(borderView)

    // Cancel Button
    let cancelButton = UIButton(type: .system)
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.setTitleColor(.white, for: .normal)
    cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    cancelButton.layer.cornerRadius = 20
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    view.addSubview(cancelButton)

    // Torch Button
    let torchButton = UIButton(type: .system)
    torchButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
    torchButton.tintColor = .white
    torchButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    torchButton.layer.cornerRadius = 20
    torchButton.translatesAutoresizingMaskIntoConstraints = false
    torchButton.addTarget(self, action: #selector(handleTorchToggle), for: .touchUpInside)
    view.addSubview(torchButton)

    NSLayoutConstraint.activate([
      cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 90),
      cancelButton.heightAnchor.constraint(equalToConstant: 40),

      torchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      torchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      torchButton.widthAnchor.constraint(equalToConstant: 44),
      torchButton.heightAnchor.constraint(equalToConstant: 40),
    ])
  }

  @objc private func handleCancel() {
    dismiss(animated: true) { [weak self] in
      self?.onCancel?()
    }
  }

  @objc private func handleTorchToggle() {
    guard captureDevice.hasTorch else { return }
    do {
      try captureDevice.lockForConfiguration()
      captureDevice.torchMode = (captureDevice.torchMode == .on) ? .off : .on
      captureDevice.unlockForConfiguration()
    } catch {
      print("Error toggling torch: \(error.localizedDescription)")
    }
  }

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard !hasScanned,
          let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
          let stringValue = metadataObj.stringValue,
          !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    hasScanned = true
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    captureSession?.stopRunning()

    dismiss(animated: true) { [weak self] in
      self?.onScanSuccess?(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }
  }
}
