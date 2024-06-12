//
//  AVFoundationCameraViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/11.
//

import UIKit
import AVFoundation
import SnapKit
import CoreMotion

class AVFoundationCameraViewController: UIViewController {

  private lazy var captureSession: AVCaptureSession = {
    let captureSession = AVCaptureSession()
    captureSession.sessionPreset = .photo
    return captureSession
  }()

  private lazy var captureDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)

  private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspect
    previewLayer.connection?.videoOrientation = .portrait
    return previewLayer
  }()

  private lazy var previewBaseView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()

  private lazy var captureAreaView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.isUserInteractionEnabled = false
    return view
  }()

  private lazy var overlayView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    view.isUserInteractionEnabled = false
    return view
  }()

  private lazy var shutterButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 30
    button.layer.masksToBounds = true
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .white
    return button
  }()

  private let motionManager: CMMotionManager = {
    let manager = CMMotionManager()
    manager.deviceMotionUpdateInterval = 0.5
    return manager
  }()
  private let motionOperationQueue = OperationQueue()

  private var currentDeviceOrientation: UIDeviceOrientation = .portrait

  deinit { motionManager.stopDeviceMotionUpdates() }

  override func viewDidLoad() {
    super.viewDidLoad()

    Task {
      guard await authorize() else { return }

      initLayout()

      Task.detached {
        do {
          await self.captureSession.beginConfiguration()
          try await self.setupCaptureSession()
          await self.captureSession.commitConfiguration()
          await self.captureSession.startRunning()
        } catch {
          print("testing___", error)
          await self.captureSession.commitConfiguration()
        }
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startObserveDeviceMotion()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard let zoomFactor = captureDevice?.virtualDeviceSwitchOverVideoZoomFactors.first else {
      return
    }
    try? captureDevice?.lockForConfiguration()
    captureDevice?.videoZoomFactor = CGFloat(truncating: zoomFactor)
    captureDevice?.unlockForConfiguration()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    self.view.layoutIfNeeded()
    maskOverlay(with: captureAreaView.frame)
    previewLayer.frame = previewBaseView.bounds
  }

  private func authorize() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    var isAuthorized = status == .authorized
    if status == .notDetermined {
      isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
    }
    return isAuthorized
  }

  /// AVCaptureSession の設定
  private func setupCaptureSession() throws {
    guard let captureDevice else {
      throw NSError(domain: "com.example.FilteringCamera", code: -1001, userInfo: nil)
    }

    let input = try AVCaptureDeviceInput(device: captureDevice)
    captureSession.addInput(input)

    let output = AVCapturePhotoOutput()
    output.setPreparedPhotoSettingsArray(
      [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])],
      completionHandler: nil
    )
    captureSession.addOutput(output)
  }

  private func startObserveDeviceMotion() {
    guard motionManager.isDeviceMotionAvailable else { return }

    motionManager.startDeviceMotionUpdates(
      using: .xMagneticNorthZVertical,
      to: motionOperationQueue) { [weak self] deviceMotion, error in
        guard let self, let deviceMotion else { return }

        let xAxis = deviceMotion.gravity.x
        if xAxis > 0.65 {
          self.currentDeviceOrientation = .landscapeRight
        } else if xAxis < -0.65 {
          self.currentDeviceOrientation = .landscapeLeft
        } else {
          self.currentDeviceOrientation = .portrait
        }

        print("testing___orientation", self.currentDeviceOrientation.rawValue)
    }
  }

  private func initLayout() {
    view.backgroundColor = .black

    view.addSubview(previewBaseView)
    previewBaseView.layer.addSublayer(previewLayer)
    previewBaseView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.left.right.equalToSuperview()
    }

    previewBaseView.addSubview(overlayView)
    overlayView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    overlayView.addSubview(captureAreaView)
    captureAreaView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalToSuperview()
      make.height.equalTo(captureAreaView.snp.width)
    }

    let bottomView = UIView()
    bottomView.backgroundColor = .clear

    bottomView.addSubview(shutterButton)
    shutterButton.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(60)
    }

    view.addSubview(bottomView)
    bottomView.snp.makeConstraints { make in
      make.top.equalTo(previewBaseView.snp.bottom)
      make.left.right.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(160)
    }

    shutterButton.addAction(.init { [weak self] _ in
      self?.capturePhoto()
      self?.motionManager.stopDeviceMotionUpdates()
    }, for: .touchUpInside)
  }

  private func capturePhoto() {
    let settings = AVCapturePhotoSettings()
    settings.flashMode = .auto
//    settings.maxPhotoDimensions = .init(width:, height:)
//    settings.photoQualityPrioritization = .quality
    guard let photoOutput = captureSession.outputs.first as? AVCapturePhotoOutput else { return }
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  /// オーバーレイのマスク（切り抜き）を設定
  private func maskOverlay(with maskingRect: CGRect) {
    let maskLayer = CAShapeLayer()
    maskLayer.fillRule = .evenOdd
    let path = CGMutablePath()
    path.addRect(overlayView.bounds)
    path.addRect(maskingRect)
    maskLayer.path = path
    overlayView.layer.mask = maskLayer
  }

  /// 画像の中央を正方形にトリミング
  private func trimToSquare(image: UIImage) -> UIImage {
    var _image: UIImage = image
    let side: CGFloat = _image.size.width < _image.size.height ? _image.size.width : _image.size.height
    let origin: CGPoint = _image.size.width < _image.size.height
      ? CGPoint(x: 0.0, y: (_image.size.width - _image.size.height) * 0.5)
      : CGPoint(x: (_image.size.height - _image.size.width) * 0.5, y: 0.0)

    UIGraphicsBeginImageContextWithOptions(CGSize(width: side, height: side), false, 0.0)
    _image.draw(in: CGRect(origin: origin, size: CGSize(width: _image.size.width, height: _image.size.height)))
    _image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return _image
  }
}

extension AVFoundationCameraViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }

    print("testing___imageOrientation", image.imageOrientation.rawValue)
    let fixed = image.fixOrientation()
    print("testing___imageOrientation", fixed.imageOrientation.rawValue)
    let squaredImage = trimToSquare(image: fixed)

    let navigationController = UINavigationController(rootViewController: PhotoEditViewController(image:  squaredImage))
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: false)
  }
}

extension UIImage {
  func fixOrientation() -> UIImage {
    if self.imageOrientation == .up {
      return self
    }
    var transform = CGAffineTransform.identity
    let width = self.size.width
    let height = self.size.height

    switch self.imageOrientation {
    case .down, .downMirrored:
      transform = transform.translatedBy(x: width, y: height)
    case .left, .leftMirrored:
      transform = transform.translatedBy(x: width, y: 0)
      transform = transform.rotated(by: CGFloat(Double.pi / 2))
    case .right, .rightMirrored:
      transform = transform.translatedBy(x: 0, y: height)
      transform = transform.rotated(by: CGFloat(-Double.pi / 2))
    default:
      break
    }

    switch self.imageOrientation {
    case .upMirrored, .downMirrored:
      transform = transform.translatedBy(x: width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
      transform = transform.translatedBy(x: height, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    default:
      break
    }
    let cgimage = self.cgImage!

    let context = CGContext(
      data: nil, width: Int(width), height: Int(height),
      bitsPerComponent: cgimage.bitsPerComponent, bytesPerRow: 0,
      space: cgimage.colorSpace!,
      bitmapInfo: cgimage.bitmapInfo.rawValue)!

    context.concatenate(transform)

    switch self.imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      context.draw(cgimage, in: CGRect(x: 0, y: 0, width: height, height: width))
    default:
      context.draw(cgimage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    let cgimg = context.makeImage()
    let img = UIImage(cgImage: cgimg!)
    return img
  }
}
