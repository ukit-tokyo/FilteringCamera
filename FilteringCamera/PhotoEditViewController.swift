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
    imageView.layer.cornerRadius = 8
    return imageView
  }()

  private lazy var filterSelectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 8
    layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    layout.itemSize = cellSize
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    return collectionView
  }()

  private let cellSize = CGSize(width: 100, height: 124)

  private let image: UIImage

  init(image: UIImage) {
    self.image = image
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

    toolView.addSubview(filterSelectionView)
    filterSelectionView.snp.makeConstraints { make in
      make.top.equalToSuperview().inset(8)
      make.left.right.equalToSuperview()
      make.height.equalTo(cellSize.height)
    }

    canvasView.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalToSuperview().inset(16)
      make.height.equalTo(imageView.snp.width)
    }

    filterSelectionView.dataSource = self
    filterSelectionView.delegate = self
    filterSelectionView.register(FilterItemCell.self, forCellWithReuseIdentifier: "FilterItemCell")
  }
}

extension PhotoEditViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    10
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterItemCell", for: indexPath) as! FilterItemCell
    cell.titleLabel.text = "title"
    cell.imageView.image = image
    return cell
  }
}

extension PhotoEditViewController {
  final class FilterItemCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14, weight: .regular)
      label.textColor = .white
      label.textAlignment = .center
      return label
    }()

    lazy var imageView: UIImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.layer.cornerRadius = 8
      return imageView
    }()

    override init(frame: CGRect) {
      super.init(frame: frame)

      contentView.backgroundColor = .clear
      
      contentView.addSubview(titleLabel)
      titleLabel.snp.makeConstraints { make in
        make.top.left.right.equalToSuperview()
      }
      contentView.addSubview(imageView)
      imageView.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(4)
        make.left.right.equalToSuperview()
        make.height.equalTo(imageView.snp.width)
      }
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
  }
}
