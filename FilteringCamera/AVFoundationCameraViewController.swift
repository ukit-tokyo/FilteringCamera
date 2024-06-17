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
    return view
  }()

  private lazy var bottomView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
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

  private lazy var flashButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24))), for: .normal)
    button.setImage(UIImage(systemName: "bolt.slash", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24))), for: .selected)
    button.tintColor = .white
    return button
  }()

  private let motionManager: CMMotionManager = {
    let manager = CMMotionManager()
    manager.accelerometerUpdateInterval = 0.5
    return manager
  }()
  private let motionOperationQueue = OperationQueue()

  private var currentDeviceOrientation: UIDeviceOrientation = .portrait

  deinit { motionManager.stopAccelerometerUpdates() }

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

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    // TODO: 画面回転アニメーションを無効にしたいが無効化されない
//    UIView.setAnimationsEnabled(false)
//    coordinator.animate(alongsideTransition: nil) { _ in
//      UIView.setAnimationsEnabled(true)
//    }
    super.viewWillTransition(to: size, with: coordinator)

    print("testing___deviceOrientation", UIDevice.current.orientation.rawValue)

    let orientation = UIDevice.current.orientation

    currentDeviceOrientation = orientation

    switch orientation {
    case .portrait:
      layoutForPortrait()
      previewLayer.connection?.videoOrientation = .portrait
    case .landscapeLeft:
      layoutForLandscapeLeft()
      previewLayer.connection?.videoOrientation = .landscapeRight
    case .landscapeRight:
      layoutForLandscapeRight()
      previewLayer.connection?.videoOrientation = .landscapeLeft
    default: break
    }
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
    guard motionManager.isAccelerometerAvailable else { return }

    motionManager.startAccelerometerUpdates(to: motionOperationQueue) { [weak self] data, error in
      guard let data, let self else { return }
      let x = data.acceleration.x
      let y = data.acceleration.y

      // portraitUpSideDown を検知する。UpSideDownがサポートされてないのiPhoneがあるため
      if x < 0.25 , y > 0.25 {
        self.currentDeviceOrientation = .portraitUpsideDown
      }
    }
  }

  private func initLayout() {
    view.backgroundColor = .black
    view.addSubview(previewBaseView)
    view.addSubview(bottomView)
    previewBaseView.layer.addSublayer(previewLayer)
    previewBaseView.addSubview(overlayView)
    overlayView.addSubview(captureAreaView)
    overlayView.addSubview(flashButton)
    bottomView.addSubview(shutterButton)

    layoutForPortrait()

    shutterButton.addAction(.init { [weak self] _ in
      self?.capturePhoto()
      self?.motionManager.stopAccelerometerUpdates()
    }, for: .touchUpInside)

    flashButton.addAction(.init { [weak self] _ in
      self?.flashButton.isSelected.toggle()
    }, for: .touchUpInside)
  }

  private func layoutForPortrait() {
    previewBaseView.snp.remakeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.left.right.equalToSuperview()
    }

    overlayView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    flashButton.snp.remakeConstraints { make in
      make.top.right.equalToSuperview().inset(24)
    }

    captureAreaView.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalToSuperview()
      make.height.equalTo(captureAreaView.snp.width)
    }

    shutterButton.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(60)
    }

    bottomView.snp.remakeConstraints { make in
      make.top.equalTo(previewBaseView.snp.bottom)
      make.left.right.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(160)
    }
  }

  private func layoutForLandscapeLeft() {
    previewBaseView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalTo(view.safeAreaLayoutGuide)
    }

    overlayView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    captureAreaView.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.height.equalToSuperview()
      make.width.equalTo(captureAreaView.snp.height)
    }

    shutterButton.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(60)
    }

    bottomView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.left.equalTo(previewBaseView.snp.right)
      make.right.equalTo(view.safeAreaLayoutGuide)
      make.width.equalTo(160)
    }
  }

  private func layoutForLandscapeRight() {
    previewBaseView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.right.equalTo(view.safeAreaLayoutGuide)
    }

    overlayView.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }

    captureAreaView.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.height.equalToSuperview()
      make.width.equalTo(captureAreaView.snp.height)
    }

    shutterButton.snp.remakeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(60)
    }

    bottomView.snp.remakeConstraints { make in
      make.top.bottom.equalToSuperview()
      make.right.equalTo(previewBaseView.snp.left)
      make.left.equalTo(view.safeAreaLayoutGuide)
      make.width.equalTo(160)
    }
  }

  private func capturePhoto() {
    let settings = AVCapturePhotoSettings()
    settings.flashMode = flashButton.isSelected ? .auto : .off
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
}

// MARK: - delegate

extension AVFoundationCameraViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }

    // TODO: 以下の画像変換処理を最適化する。重すぎてUIスレッド固まってる

    let fixed = ImageUtility.fixOrientation(uiImage: image)
    let squared = ImageUtility.trimToSquare(uiImage: fixed)
    let angle = (-CGFloat.pi / 2) * CGFloat(truncating: currentDeviceOrientation.coefficientForAngle as NSNumber)
    let rotated = ImageUtility.rotate(uiImage: squared, angle: angle)

    // TODO: オリエンテーション対応
//    let navigationController = UINavigationController(rootViewController: PhotoEditViewController(image:  rotated))
    let navigationController = UINavigationController(rootViewController: PhotoEditViewController(image:  squared))
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: false)
  }
}

// MARK: - utility

class ImageUtility {
  /// 画像のオリエンテーションを .up に正す
  static func fixOrientation(uiImage: UIImage) -> UIImage {
    if uiImage.imageOrientation == .up {
      return uiImage
    }
    var transform = CGAffineTransform.identity
    let width = uiImage.size.width
    let height = uiImage.size.height

    switch uiImage.imageOrientation {
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

    switch uiImage.imageOrientation {
    case .upMirrored, .downMirrored:
      transform = transform.translatedBy(x: width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
      transform = transform.translatedBy(x: height, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    default:
      break
    }
    let cgImage = uiImage.cgImage!

    let context = CGContext(
      data: nil, width: Int(width), height: Int(height),
      bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
      space: cgImage.colorSpace!,
      bitmapInfo: cgImage.bitmapInfo.rawValue)!

    context.concatenate(transform)

    switch uiImage.imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
    default:
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    let cgimg = context.makeImage()
    return UIImage(cgImage: cgimg!)
  }

  /// 画像の中央を正方形にトリミング
  static func trimToSquare(uiImage: UIImage) -> UIImage {
    var image: UIImage = uiImage
    let side: CGFloat = image.size.width < image.size.height ? image.size.width : image.size.height
    let origin: CGPoint = image.size.width < image.size.height
      ? CGPoint(x: 0.0, y: (image.size.width - image.size.height) * 0.5)
      : CGPoint(x: (image.size.height - image.size.width) * 0.5, y: 0.0)

    UIGraphicsBeginImageContextWithOptions(CGSize(width: side, height: side), false, 0.0)
    image.draw(in: CGRect(origin: origin, size: CGSize(width: image.size.width, height: image.size.height)))
    image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return image
  }

  /// 画像を指定のアングルへ回転させる
  static func rotate(uiImage: UIImage, angle: CGFloat) -> UIImage {
    let transform = CGAffineTransform(rotationAngle: angle)
    let sizeRect = CGRect(origin: CGPoint.zero, size: uiImage.size)
    let destRect = sizeRect.applying(transform)
    let destinationSize = destRect.size

    UIGraphicsBeginImageContext(destinationSize)
    let context = UIGraphicsGetCurrentContext()!
    context.translateBy(x: destinationSize.width / 2.0, y: destinationSize.height / 2.0)
    context.rotate(by: angle)
    uiImage.draw(in: CGRect(x: -uiImage.size.width / 2.0, y: -uiImage.size.height / 2.0, width: uiImage.size.width, height: uiImage.size.height))

    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return newImage
  }
}

// MARK: - extension

extension UIDeviceOrientation {
  var coefficientForAngle: Int {
    switch self {
    case .portrait: return 0
    case .landscapeLeft: return 1
    case .portraitUpsideDown: return 2
    case .landscapeRight: return 3
    default: return 0
    }
  }
}
