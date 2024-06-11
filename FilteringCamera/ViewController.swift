//
//  ViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
  private lazy var avFoundationCameraButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 12
    button.layer.masksToBounds = true
    button.setTitle("AV FOUNDATION", for: .normal)
    button.setTitleColor(.label, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
    button.backgroundColor = .systemGray
    return button
  }()

  private lazy var imagePickerCameraButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 12
    button.layer.masksToBounds = true
    button.setTitle("IMAGE PICKER", for: .normal)
    button.setTitleColor(.label, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
    button.backgroundColor = .systemGray
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(avFoundationCameraButton)
    avFoundationCameraButton.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalTo(200)
      make.height.equalTo(44)
    }

    view.addSubview(imagePickerCameraButton)
    imagePickerCameraButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(avFoundationCameraButton.snp.bottom).offset(16)
      make.size.equalTo(avFoundationCameraButton)
    }

    avFoundationCameraButton.addAction(.init { _ in
      let vc = AVFoundationCameraViewController()
      vc.modalPresentationStyle = .fullScreen
      self.present(vc, animated: true)
    }, for: .touchUpInside)

    imagePickerCameraButton.addAction(.init { _ in
      self.presentImagePicker()
    }, for: .touchUpInside)
  }

  private func presentImagePicker() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.allowsEditing = false
    imagePicker.delegate = self

//    let overlay = UIView()
//    overlay.backgroundColor = UIColor.red.withAlphaComponent(0.5)
//    imagePicker.cameraOverlayView = overlay

    present(imagePicker, animated: true)
  }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[.originalImage] as? UIImage else { return }

    picker.dismiss(animated: false) { [weak self] in
      let vc = UINavigationController(rootViewController: PhotoEditViewController(image: image))
      vc.modalPresentationStyle = .fullScreen
      self?.present(vc, animated: false)
    }
  }
}
