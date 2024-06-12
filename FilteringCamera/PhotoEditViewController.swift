//
//  PhotoEditViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit

final class PhotoEditViewController: UIViewController {
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  init(image: UIImage) {
    super.init(nibName: nil, bundle: nil)
    imageView.image = image
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { _ in
      self.dismiss(animated: true, completion: nil)
    })

    view.backgroundColor = .black

    let canvasView = UIView()
    canvasView.backgroundColor = .clear

    let toolView = UIView()
    toolView.backgroundColor = .clear

    view.addSubview(canvasView)
    canvasView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.left.right.equalToSuperview()
    }

    view.addSubview(toolView)
    toolView.snp.makeConstraints { make in
      make.top.equalTo(canvasView.snp.bottom)
      make.left.right.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(160)
    }

    canvasView.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalToSuperview().inset(16)
      make.height.equalTo(imageView.snp.width)
    }
  }
}
