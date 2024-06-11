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
    button.setTitle("CAMERA", for: .normal)
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

    avFoundationCameraButton.addAction(.init { _ in
      let vc = AVFoundationCameraViewController()
      vc.modalPresentationStyle = .fullScreen
      self.present(vc, animated: true)
    }, for: .touchUpInside)
  }

  private func initLayout() {
    view.addSubview(avFoundationCameraButton)
    avFoundationCameraButton.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalTo(200)
      make.height.equalTo(44)
    }
  }
}
