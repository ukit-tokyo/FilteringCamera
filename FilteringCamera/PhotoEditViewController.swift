//
//  PhotoEditViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit

private extension UIImage.Orientation {
  var nextRotation: UIImage.Orientation {
    return switch self {
    case .up: .left
    case .left: .down
    case .down: .right
    case .right: .up
    default: fatalError()
    }
  }

  var coefficientForAngle: Int {
    switch self {
    case .up: return 0
    case .right: return 1
    case .down: return 2
    case .left: return 3
    default: return 0
    }
  }
}

final class PhotoEditViewController: UIViewController {
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.layer.cornerRadius = 8
    imageView.layer.masksToBounds = true
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

  private lazy var enterButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 16
    button.layer.masksToBounds = true
    button.setTitle("完了", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
    button.backgroundColor = .red
    button.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
    return button
  }()

  private let cellSize = CGSize(width: 100, height: 124)

  private let originalImage: UIImage
  private var compactImage: UIImage!
  private let context = CIContext()

  private var currentRotation: UIImage.Orientation = .up

  init(image: UIImage) {
    self.originalImage = image
    super.init(nibName: nil, bundle: nil)
    
    imageView.image = image
    // フィルタの描画処理を軽くするために、予め画像を最小限のサイズに縮小しておく
    compactImage = minimiseImage(from: image)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { _ in
      self.dismiss(animated: true, completion: nil)
    })

    let rotationButton = UIBarButtonItem(image: .init(systemName: "rotate.left"), primaryAction: .init() { [weak self] _ in
      self?.rotateImageViewToLeft()
    })
    rotationButton.tintColor = .white

    navigationItem.rightBarButtonItems = [
      rotationButton,
    ]

    view.backgroundColor = .black

    let actionView = UIView()
    actionView.addSubview(enterButton)
    enterButton.snp.makeConstraints { make in
      make.right.equalToSuperview().inset(16)
      make.height.equalTo(32)
      make.verticalEdges.equalToSuperview().inset(24)
    }

    let canvasView = UIView()
    canvasView.backgroundColor = .clear
    canvasView.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.verticalEdges.equalToSuperview()
      make.horizontalEdges.equalToSuperview().inset(16)
      make.height.equalTo(imageView.snp.width)
    }

    let stackView = UIStackView(arrangedSubviews: [
      canvasView,
      filterSelectionView,
    ])
    stackView.axis = .vertical
    stackView.spacing = 24

    view.addSubview(stackView)
    stackView.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.horizontalEdges.equalToSuperview()
    }

    view.addSubview(actionView)
    actionView.snp.makeConstraints { make in
      make.horizontalEdges.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    filterSelectionView.snp.makeConstraints { make in
      make.height.equalTo(cellSize.height)
    }

    filterSelectionView.dataSource = self
    filterSelectionView.delegate = self
    filterSelectionView.register(FilterItemCell.self, forCellWithReuseIdentifier: "FilterItemCell")

    enterButton.addAction(.init { [weak self] _ in
      guard let self, let image = self.imageView.image else { return }
      let rotatedImage = self.rotateImage(image)
      let vc = ResultViewController()
      vc.imageView.image = rotatedImage
      self.present(vc, animated: true)
    }, for: .touchUpInside)
  }

  /// 画像を最小限のサイズに縮小する
  private func minimiseImage(from image: UIImage) -> UIImage {
    let size = CGSize(width: cellSize.width, height: cellSize.width)
    let renderer = UIGraphicsImageRenderer(size: size)
    let resizedImage = renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    return resizedImage
  }

  /// 画像のフィルタを適用する
  /// 描画処理が重いので async でメインスレッドから逃す
  private func filterImage(photoFilter: PhotoFilter, originalImage: UIImage) async -> UIImage? {
    guard let filter = photoFilter.filter else { return originalImage }

    photoFilter.parameters?.forEach { (key, value) in
      filter.setValue(value, forKey: key)
    }
    let inputImage = CIImage(image: originalImage)!
    filter.setValue(inputImage, forKey: kCIInputImageKey)

    guard let outputImage = filter.outputImage else {
      print("failed to get output image")
      return nil
    }
    guard let cgImage = context.createCGImage(outputImage, from: inputImage.extent) else {
      print("failed to create cgImage from outputImage")
      return nil
    }

    return UIImage(cgImage: cgImage)
  }

  private func rotateImageViewToLeft() {
    currentRotation = currentRotation.nextRotation
    
    let angle = CGFloat(currentRotation.coefficientForAngle) * .pi / 2
    let transform = CGAffineTransform(rotationAngle: angle)
    UIView.animate(withDuration: 0.3) {
      self.imageView.transform = transform
    }
  }

  private func rotateImage(_ image: UIImage) -> UIImage {
    let angle = CGFloat(currentRotation.coefficientForAngle) * .pi / 2
    let routated = ImageUtility.rotate(uiImage: image, angle: angle)
    return routated
  }
}

extension PhotoEditViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    photoFilters.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let filter = photoFilters[indexPath.item]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterItemCell", for: indexPath) as! FilterItemCell
    cell.titleLabel.text = filter.displayName

    Task {
      let image = await filterImage(photoFilter: filter, originalImage: compactImage)
      cell.imageView.image = image
    }

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    Task {
      let filter = photoFilters[indexPath.item]
      let image = await filterImage(photoFilter: filter, originalImage: originalImage)
      imageView.image = image
    }

    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
  }
}

extension PhotoEditViewController {
  final class FilterItemCell: UICollectionViewCell {
    override var isSelected: Bool {
      didSet { updateLayout(with: isSelected) }
    }

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
      imageView.layer.masksToBounds = true
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

    func updateLayout(with isSelected: Bool) {
      titleLabel.font = isSelected
        ? .systemFont(ofSize: 14, weight: .bold)
        : .systemFont(ofSize: 14, weight: .regular)
      imageView.transform = isSelected 
        ? CGAffineTransform(scaleX: 1.05, y: 1.05)
        : .identity
    }
  }
}
