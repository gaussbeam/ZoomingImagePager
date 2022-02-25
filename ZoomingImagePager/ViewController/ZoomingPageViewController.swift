//
//  ZoomingPageViewController.swift
//  ZoomingImagePager
//
//  Created by HANYU, Koji on 2022/02/25.
//

import UIKit

class ZoomingPageViewController: UIPageViewController {

    private var index = 0
    private let images = ["img_1", "img_2", "img_3", "img_4"]
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        
        let vc = zoomingImageViewController(at: index)!
        setViewControllers(
            [vc],
            direction: .forward,
            animated: false
        )
    }
}

extension ZoomingPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let zoomingImageView = pageViewController.viewControllers?.first as?  ZoomingImageViewController else { return }
        index = zoomingImageView.index
    }
}

extension ZoomingPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let nextIndex = index - 1
        return zoomingImageViewController(at: nextIndex)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let nextIndex = index + 1
        return zoomingImageViewController(at: nextIndex)
    }
    
    private func zoomingImageViewController(at index: Int) -> UIViewController? {
        guard index >= 0 && index < images.count else { return nil }

        let imageName = images[index]
        let input = ZoomingImageViewController.Input(
            index: index,
            image: UIImage(named: imageName)!
        )
        
        let vc = ZoomingImageViewController.instantiate()
        vc.input = input
        return vc
    }
}
