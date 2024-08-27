//
//  ImageController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 25.07.2024.
//

import UIKit
import SnapKit
import SDWebImage

final class ImageViewController: UIViewController {
    
    private let viewModel: ImageViewModel
    private let contentView = UIView()
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var activityIndicatorDelete: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var urlImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = true
        return image
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        let image = UIImage(systemName: "square.and.arrow.up")
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        let image = UIImage(systemName: "trash")
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var renameButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        let image = UIImage(systemName: "pencil")
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        let image = UIImage(systemName: "chevron.left")
        button.tintColor = .white
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var dataLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        return label
    }()
    
    private var nameFileLabel: UILabel = {
       let label = UILabel()
       label.numberOfLines = 1
       label.textColor = .white
        label.textAlignment = .center
       return label
    }()
    
    private var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private var customBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    init(viewModel: ImageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        setupView()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupView() {
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(urlImage)
        contentView.addSubview(activityIndicator)
        
        view.addSubview(customBarView)
        customBarView.addSubview(renameButton)
        customBarView.addSubview(backButton)
        customBarView.addSubview(nameFileLabel)
        customBarView.addSubview(activityIndicatorDelete)
        
        view.addSubview(infoView)
        infoView.addSubview(dataLabel)
        infoView.addSubview(shareButton)
        infoView.addSubview(deleteButton)
        
//      Добавление пинч-жеста(увелечение и уменьшение изображения)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        urlImage.addGestureRecognizer(pinchGesture)
//      Добавление свайп жеста
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(hendleSwipDown(_:)))
        swipeDownGesture.direction = .down
        urlImage.addGestureRecognizer(swipeDownGesture)
        
        setupConstraint()
    }

    private func bindViewModel() {
        self.activityIndicator.startAnimating()
        viewModel.onImageLoaded = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.urlImage.image = self.viewModel.image
                print("Изображение загруженно")
            }
        }
        
        viewModel.onImageLoadingError = { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.showAlert("Ошибка", message: "Ошибка загрузки изображения \(error)")
                print("Failed to load image: \(error)")
            }
        }
        
        dataLabel.text = viewModel.formattedDate
        nameFileLabel.text = viewModel.imageName
    }
    
    @objc func shareButtonTapped() {
        let alertController = UIAlertController(
            title: "Поделиться",
            message: nil,
            preferredStyle: .actionSheet
        )
        let shareFile = UIAlertAction(title: "Файлом", style: .default, handler: nil)
        
        let shareReference = UIAlertAction(title: "Ссылкой", style: .default, handler: nil)
    
        let destructiveAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
            alertController.addAction(shareFile)
            alertController.addAction(destructiveAction)
            alertController.addAction(shareReference)
            self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(title: nil, message: "Вы уверены, что хотите удалить файл?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            self.activityIndicatorDelete.startAnimating()
            self.viewModel.deleteFile { result in
                DispatchQueue.main.async {
                    self.activityIndicatorDelete.stopAnimating()
                    switch result {
                    case .success():
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self.showAlert("Ошибка", message: "Ошибка удаления файла: \(error.localizedDescription)")
                    }
                }
            }
        }))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = deleteButton
            popoverController.sourceRect = deleteButton.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func moreButtonTapped() {
        let renameViewModel = RenameFileViewModel(file: viewModel.item, fileName: viewModel.imageName ?? "", fileImage: viewModel.image)
        let renameVC = RenameFileViewController(viewModel: renameViewModel)
//        let renameVC = RenameFileViewController(file: viewModel.item, fileName: viewModel.imageName ?? "", fileImage: viewModel.image)
        renameViewModel.fileRenamed = { [ weak self ] newFileName in
            guard let self = self else { return }
            self.nameFileLabel.text = newFileName
            self.viewModel.imageName = newFileName
            viewModel.fileRenamed?()
        }
        self.navigationController?.pushViewController(renameVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handlePinch(_ sender: UIPinchGestureRecognizer) {
        guard let view = sender.view else { return }
        view.transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
        sender.scale = 1.0
    }
    
    @objc private func hendleSwipDown(_ sender: UISwipeGestureRecognizer) {
        guard sender.state == .ended else { return }
        
//      Начало анимации
        UIView.animate(withDuration: 0.9, delay: 0, options: .curveEaseInOut, animations: {
//      Уменьшение размера картинки
        self.urlImage.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//      Перемещение картинки вниз
        self.urlImage.center = CGPoint(x: self.urlImage.center.x, y: self.view.bounds.height + self.urlImage.bounds.height)
        self.view.alpha = 0
    }) { _ in
//      Закртие кантролера
        self.navigationController?.popViewController(animated: false)
        }
    }
}

//MARK: - SetupConstraint
extension ImageViewController {
    private func setupConstraint() {
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).inset(0)
            make.bottom.equalTo(view.snp.bottom).inset(0)
            make.left.equalTo(view.snp.left).inset(0)
            make.right.equalTo(view.snp.right).inset(0)
        }
        urlImage.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX).inset(0)
            make.centerY.equalTo(contentView.snp.centerY).inset(0)
            make.width.equalTo(contentView)
            make.height.equalTo(urlImage.snp.height)
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalTo(contentView)
            make.centerY.equalTo(contentView)
        }
        activityIndicatorDelete.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorDelete.snp.makeConstraints { make in
            make.right.equalTo(customBarView.snp.right).offset(-46)
            make.bottom.equalTo(customBarView.snp.bottom).inset(5)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        shareButton.snp.makeConstraints { make in
            make.left.equalTo(infoView.snp.left).inset(18)
            make.top.equalTo(infoView.snp.top).inset(5)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        deleteButton.snp.makeConstraints { make in
            make.right.equalTo(infoView.snp.right).inset(18)
            make.top.equalTo(infoView.snp.top).inset(5)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        infoView.snp.makeConstraints { make in
            make.left.right.equalTo(view).inset(0)
            make.bottom.equalTo(contentView.snp.bottom).inset(0)
            make.height.equalTo(80)
        }
        dataLabel.snp.makeConstraints { make in
            make.top.equalTo(infoView.snp.top).inset(15)
            make.centerX.equalTo(infoView)
        }
        customBarView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).inset(0)
            make.left.right.equalTo(view)
            make.height.equalTo(90)
        }
        renameButton.snp.makeConstraints { make in
            make.right.equalTo(customBarView.snp.right).offset(-15)
            make.bottom.equalTo(customBarView.snp.bottom).inset(5)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        backButton.snp.makeConstraints { make in
            make.left.equalTo(customBarView.snp.left).offset(15)
            make.bottom.equalTo(customBarView.snp.bottom).inset(5)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        nameFileLabel.snp.makeConstraints { make in
            make.bottom.equalTo(customBarView.snp.bottom).inset(15)
            make.width.equalTo(160)
            make.centerX.equalTo(customBarView)
        }
    }
}

