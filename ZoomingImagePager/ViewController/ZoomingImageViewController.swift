//
//  ViewController.swift
//  ZoomingImagePager
//
//  Created by HANYU, Koji on 2022/02/25.
//

import UIKit

class ZoomingImageViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageViewEqualWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewEqualHeightConstraint: NSLayoutConstraint!
    
    var input: Input!

    var index: Int {
        input.index
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureScrollView()
        // ZoomingPageViewController から input が設定されたタイミングではビューが読み込まれていないため，ここで画像をセットする
        setImage()
    }

    override func viewDidLayoutSubviews() {
        updateImageViewsEqualConstraint()
        preventScrollingToEmptyAreaOfImageView()
    }

    @objc func viewDidDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            let tappedLocation = sender.location(in: imageView)
            zoomImage(to: tappedLocation)
        } else {
            resetZooming()
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        preventScrollingToEmptyAreaOfImageView()
    }
}

// MARK: - Configure views

private extension ZoomingImageViewController {
    var scrollViewSize: CGSize { scrollView.frame.size }
    var imageViewSize: CGSize { imageView.frame.size }
    
    func setImage() {
        imageView.image = input.image
        
        resizeImageViewToFitContent()
        updateImageViewsEqualConstraint()
        preventScrollingToEmptyAreaOfImageView()
    }
    
    func configureScrollView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidDoubleTap(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tapGestureRecognizer)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
    }

    /// `imageView` と `scrollView` 間のEqual constraintの設定を更新する
    /// - NOTE: `imageView` が `scrollView` より横長の場合はビュー間の幅を、そうでなければビュー間の高さを一致させる
    func updateImageViewsEqualConstraint() {
        let imageAspect = imageViewSize.width / imageViewSize.height
        let scrollViewAspect = scrollViewSize.width / scrollViewSize.height
        let isImageViewWiderThanScrollView = imageAspect > scrollViewAspect

        imageViewEqualWidthConstraint.priority = isImageViewWiderThanScrollView ? .required : .defaultHigh
        imageViewEqualHeightConstraint.priority = isImageViewWiderThanScrollView ? .defaultHigh : .required
    }

    func resizeImageViewToFitContent() {
        guard let imageSize = imageView.image?.size else { return }
        let ratio = imageSize.width/imageSize.height
        let aspectConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: ratio)
        // Priorityが `required` だと実行時に警告が出る & `defaultHigh` だと回転時のサイズ調整が適切に行えないため，値を直接指定
        aspectConstraint.priority = UILayoutPriority(999)
        aspectConstraint.isActive = true
        view.layoutIfNeeded()
    }
}


// MARK: - Zooming

private extension ZoomingImageViewController {
    /// 画像をズームした際に余白部分までスクロールできないようにする
    func preventScrollingToEmptyAreaOfImageView() {
        let imageSize = calcCurrentImageViewSize()
        let areaSize = scrollView.frame.size

        // レイアウト時に1pt未満のズレが生じ，PageViewControllerのスクロールが妨げられる場合があるため `floor()` で丸める
        let horizontalInset = floor(0.5 * max(areaSize.width - imageSize.width, 0))
        let verticalInset = floor(0.5 * max(areaSize.height - imageSize.height, 0))

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset)
    }

    func calcCurrentImageViewSize() -> CGSize {
        /// ズーム倍率=1の場合の`ImageView`のサイズ
        func calcNonZoomedImageViewSize() -> CGSize {
            let widthRatio = scrollViewSize.width / imageViewSize.width
            let heightRatio = scrollViewSize.height / imageViewSize.height
            let isImageWiderThanScrollView = widthRatio < heightRatio

            // 画像とScrollViewのアスペクト比から実際のサイズを求める
            // どちらか一方の辺は必ず一致するので、一致する辺の長さとアスペクト比からImageViewのサイズを計算
            if isImageWiderThanScrollView {
                return CGSize(width: scrollView.frame.width,
                              height: scrollView.frame.width / imageViewSize.width * imageViewSize.height)
            } else {
                return CGSize(width: scrollView.frame.height / imageViewSize.height * imageViewSize.width,
                              height: scrollView.frame.height)
            }
        }
        
        let originSize = calcNonZoomedImageViewSize()
        let currentScale = scrollView.zoomScale
        return CGSize(width: originSize.width * currentScale,
                      height: originSize.height * currentScale)
    }

    func zoomImage(to point: CGPoint) {
        let scale = scrollView.maximumZoomScale
        let origin = CGPoint(x: point.x - (point.x / scale),
                             y: point.y - (point.y / scale))
        let zoomedRectSize = CGSize(width: imageViewSize.width / scale,
                                    height: imageViewSize.height / scale)
        scrollView.zoom(to: CGRect(origin: origin, size: zoomedRectSize), animated: true)
    }

    func resetZooming() {
        let scale = scrollView.minimumZoomScale
        scrollView.setZoomScale(scale, animated: true)
    }
}

// MARK: - Interface

extension ZoomingImageViewController {
    struct Input {
        var index: Int
        var image: UIImage
    }
    
    static func instantiate() -> ZoomingImageViewController {
        UIStoryboard(name: "ZoomingImageViewController", bundle: nil).instantiateInitialViewController() as! ZoomingImageViewController
    }
}
