//
//  PhotoEditViewController.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/03.
//

import UIKit

final class PhotoEditViewController: UIViewController {
  private lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.minimumZoomScale = 1
    scrollView.maximumZoomScale = 2
//    scrollView.clipsToBounds = false
    return scrollView
  }()

  private var overlay: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.alpha = 0.5
    view.isUserInteractionEnabled = false
    return view
  }()

  private let image: UIImage

  private let screenWidth = UIScreen.main.bounds.width
  private let screenHeight = UIScreen.main.bounds.height
  private let horizontalInset: CGFloat = 16

  var beforeVC = "ChangeProfileVC"

  var cropArea: CGRect {
    return CGRect(
      x: horizontalInset,
      y: screenHeight / 2 - (screenWidth - (horizontalInset * 2)) / 2,
      width: screenWidth - (horizontalInset * 2),
      height: screenWidth - (horizontalInset * 2))
  }

  init(image: UIImage) {
    self.image = image
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: .init { _ in
      self.dismiss(animated: true, completion: nil)
    })

    let imageWidth = image.size.width
    let imageHeight = image.size.height

    if imageWidth < imageHeight { // 縦長画像
      let ratio = imageHeight / imageWidth
      imageView.frame.size = CGSize(width: screenWidth - (horizontalInset * 2), height: (screenWidth - (horizontalInset * 2)) * ratio)
      // scrollViewのサイズ設定 スクロール操作可能エリアを広げるために十分に高さを確保する
      scrollView.frame.size = CGSize(width: imageView.frame.width, height: imageView.frame.width * 1.5)
      let inset = (scrollView.frame.height - imageView.frame.width) / 2
      scrollView.contentInset.top = inset
      scrollView.contentInset.bottom = inset
    } else { // 横長画像
      let ratio = imageWidth / imageHeight
      imageView.frame.size = CGSize(width: (screenWidth - (horizontalInset * 2)) * ratio, height: screenWidth - (horizontalInset * 2))
      scrollView.frame.size = CGSize(width: screenWidth, height: imageView.frame.height)
      scrollView.contentInset.left = horizontalInset
      scrollView.contentInset.right = horizontalInset
    }

    scrollView.contentSize = imageView.frame.size
    scrollView.center = view.center

    // imageViewにライブラリで選択した画像を入れる
    imageView.image = image

    scrollView.delegate = self

    scrollView.addSubview(imageView)
    view.addSubview(scrollView)

    addCropView()
    setUpBorder()
  }

  // クロップ範囲を表示するViewの作成
  func addCropView() {
    overlay.frame = view.bounds

    // クロップする範囲で図形を作る（丸型にする）
    let cropAreaPath = UIBezierPath(roundedRect: cropArea, cornerRadius: view.frame.width / 2)
    // 外枠の範囲で図形を作る（背景が黒になる範囲）
    let outsideCropAreaPath = UIBezierPath(rect: scrollView.frame)
    // クロップ範囲の丸型図形の下にViewの幅の図形を追加する
    cropAreaPath.append(outsideCropAreaPath)

    let cropAreaLayer = CAShapeLayer()
    // cropAreaPathの持つ図形のpathを渡す
    cropAreaLayer.path = cropAreaPath.cgPath
    // クロップするエリアの塗り潰し解除
    cropAreaLayer.fillRule = .evenOdd
    overlay.layer.mask = cropAreaLayer

    view.addSubview(overlay)
  }

  // クロップ範囲の枠を作成
  func setUpBorder() {
    let border = CAShapeLayer()
    let borderPath = UIBezierPath(rect: cropArea)
    border.path = borderPath.cgPath
    border.lineWidth = 1
    border.strokeColor = UIColor.white.cgColor
    overlay.layer.addSublayer(border)
  }

  @IBAction func pushCropButton(_ sender: Any) {

    // クロップ領域の位置とサイズを取得
    let cropAreaRect = overlay.convert(cropArea, to: scrollView)

    // 画像がどのくらい拡大されたかの倍率
    let imageViewScale = max(
      image.size.width / imageView.frame.width,
      image.size.height / imageView.frame.height
    )

    // クロップする範囲を定義
    let cropZone = CGRect(
      x: (cropAreaRect.origin.x - imageView.frame.origin.x) * imageViewScale,
      y: (cropAreaRect.origin.y - imageView.frame.origin.y) * imageViewScale,
      width: cropAreaRect.width * imageViewScale,
      height: cropAreaRect.height * imageViewScale
    )

    let croppedCGImage = image.cgImage?.cropping(to: cropZone)

    if let croppedCGImage = croppedCGImage {
      // 元の画像の向きを元に向きを再調整する
      let croppedImage = UIImage(cgImage: croppedCGImage, scale: 0, orientation: image.imageOrientation)

//      if beforeVC == "ChangeProfileVC" {
//        let changeProfileVC = navigationController?.viewControllers.first(where: {$0 is ChangeProfileViewController}) as! ChangeProfileViewController
//        changeProfileVC.customView.icon.image = croppedImage
//
//        navigationController?.popToViewController(changeProfileVC, animated: true)
//      } else if beforeVC == "ProfileModificationVC" {
//        let profileModificationVC = navigationController?.viewControllers.first(where: {$0 is ProfileModificationViewController}) as! ProfileModificationViewController
//        profileModificationVC.customView.icon.image = croppedImage
//
//        navigationController?.popToViewController(profileModificationVC, animated: true)
//      }

    }
  }

//  // 戻るボタンが押された時の処理
//  @IBAction func pushBackButton(_ sender: Any) {
//    self.navigationController?.popViewController(animated: true)
//  }
}

extension PhotoEditViewController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
}
