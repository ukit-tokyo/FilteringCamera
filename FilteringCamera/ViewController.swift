//
//  ViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit
import AVFoundation
import SnapKit

class ViewController: UIViewController {

  private var captureSession: AVCaptureSession!

  private lazy var shutterButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 30
    button.layer.masksToBounds = true
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .systemGray
    return button
  }()

  private lazy var captureAreaView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    return view
  }()

  private lazy var overlay: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    Task {
      guard await authorize() else { return }

      do {
        self.captureSession = try avCaptureSession()
      } catch {
        print("Error: \(error)")
      }

      initLayout()

      Task.detached {
        await self.captureSession.startRunning()
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    maskOverlay(with: captureAreaView.frame)
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
  private func avCaptureSession() throws -> AVCaptureSession {
    let captureSession = AVCaptureSession()
    captureSession.sessionPreset = .photo

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      throw NSError(domain: "com.example.FilteringCamera", code: -1001, userInfo: nil)
    }

    let input = try AVCaptureDeviceInput(device: device)
    captureSession.addInput(input)

    let output = AVCapturePhotoOutput()
    output.setPreparedPhotoSettingsArray(
      [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])],
      completionHandler: nil
    )
    captureSession.addOutput(output)

    return captureSession
  }

  /// カメラのプレビューレイヤを生成
  private func cameraPreviewLayer() -> AVCaptureVideoPreviewLayer {
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
    previewLayer.videoGravity = .resizeAspect
    // プレビューレイヤの表示の向きを設定
    previewLayer.connection?.videoOrientation = .portrait
    previewLayer.frame = view.frame
    return previewLayer
  }

  private func initLayout() {
    view.layer.insertSublayer(cameraPreviewLayer(), at: 0)

    view.addSubview(overlay)
    overlay.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    view.addSubview(shutterButton)
    shutterButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
      make.width.height.equalTo(60)
    }
    view.addSubview(captureAreaView)
    captureAreaView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview()
      make.width.equalToSuperview()
      make.height.equalTo(captureAreaView.snp.width)
    }

    shutterButton.addAction(.init { [weak self] _ in
      self?.capturePhoto()
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
    path.addRect(overlay.bounds)
    path.addRect(maskingRect)
    maskLayer.path = path
    overlay.layer.mask = maskLayer
  }

  /// 画像の中央を正方形にトリミング
  private func trim(image: UIImage) -> UIImage {
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

extension ViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }

    let trimmedImage = trim(image: image)

    let navigationController = UINavigationController(rootViewController: PhotoEditViewController(image: trimmedImage))
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: false)
  }
}
