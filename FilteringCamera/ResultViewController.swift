//
//  ResultViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/17.
//

import UIKit

final class ResultViewController: UIViewController {
  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.layer.cornerRadius = 0
    imageView.layer.masksToBounds = true
    return imageView
  }()

  private lazy var saveButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 16
    button.layer.masksToBounds = true
    button.setTitle("保存", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
    button.backgroundColor = .red
    return button
  }()

  private lazy var stackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [imageView, saveButton])
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 24
    return stackView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    view.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.horizontalEdges.equalToSuperview().inset(16)
    }

    imageView.snp.makeConstraints { make in
      make.height.equalTo(imageView.snp.width)
    }

    saveButton.snp.makeConstraints { make in
      make.width.equalTo(200)
      make.height.equalTo(44)
    }

    saveButton.addAction(.init(handler: { _ in
      self.dismiss(animated: true, completion: nil)
    }), for: .touchUpInside)
  }
}
