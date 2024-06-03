//
//  ViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

  private var captureSession: AVCaptureSession!

  override func viewDidLoad() {
    super.viewDidLoad()

    Task {
      guard await authorize() else { return }
      do {
        self.captureSession = try avCaptureSession()
      } catch {

      }
      let previewLayer = self.cameraPreviewLayer()
      view.layer.insertSublayer(previewLayer, at: 0)

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
}

