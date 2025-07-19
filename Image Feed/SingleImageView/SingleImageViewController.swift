import UIKit

final class SingleImageViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var fullImageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
       
        // Запускаем процесс загрузки картинки
            loadImage()
    }
    
    @IBAction private func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
    
    private func loadImage() {
        // 1. Показываем лоадер
        UIBlockingProgressHUD.show()
        
        // 2. Устанавливаем плейсхолдер и начинаем загрузку
        imageView.kf.setImage(with: fullImageURL) { [weak self] result in
            // 3. Скрываем лоадер по завершению
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                // 4. При успехе - масштабируем картинку
                let image = imageResult.image
                self.imageView.frame.size = image.size // <-- Важно! Устанавливаем размер UIImageView
                self.rescaleAndCenterImageInScrollView(image: image)
            case .failure:
                // 5. При ошибке - показываем алерт
                self.showError()
            }
        }
    }

    private func showError() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Что-то пошло не так. Попробовать ещё раз?",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Не надо", style: .cancel)
        let retryAction = UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadImage() // Повторно вызываем загрузку
        }
        
        alert.addAction(cancelAction)
        alert.addAction(retryAction)
        
        self.present(alert, animated: true)
    }
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = max(minZoomScale, min(maxZoomScale, max(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerImageInScrollView()
    }
    
    private func centerImageInScrollView() {
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize
        let horizontalInset = max(0, (boundsSize.width - contentSize.width) / 2)
        let verticalInset = max(0, (boundsSize.height - contentSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        scrollView.contentOffset = CGPoint(x: -horizontalInset, y: -verticalInset)
    }
}

