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

    do {
      let input = try AVCaptureDeviceInput(device: device)
      captureSession.addInput(input)
      let output = AVCapturePhotoOutput()
      output.setPreparedPhotoSettingsArray(
        [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])],
        completionHandler: nil
      )
      captureSession.addOutput(output)
      return captureSession
    } catch {
      throw error
    }
  }

  /// カメラのプレビューレイヤを生成
  private func cameraPreviewLayer() -> AVCaptureVideoPreviewLayer  {
    // 指定したAVCaptureSessionでプレビューレイヤを初期化
    let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
    cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    // プレビューレイヤの表示の向きを設定
    cameraPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    cameraPreviewLayer.frame = view.frame
    return cameraPreviewLayer
  }

  private func initLayout() {
    let previewLayer = cameraPreviewLayer()
    view.layer.insertSublayer(previewLayer, at: 0)

    view.addSubview(shutterButton)
    shutterButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
      make.width.height.equalTo(60)
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
}

extension ViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else { return }

    let navigationController = UINavigationController(rootViewController: PhotoEditViewController(image: image))
    navigationController.modalPresentationStyle = .fullScreen
    present(navigationController, animated: true)
  }
}
