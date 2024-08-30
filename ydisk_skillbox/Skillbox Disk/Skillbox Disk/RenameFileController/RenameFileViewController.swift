//
//  RenameFileViewControllerMVVM.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 27.08.2024.
//

import UIKit

class RenameFileViewController: UIViewController {
    
    private var renameFileViewModel: RenameFileViewModel
    
    private let activityIndicatorRenameFile: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor(named: "TextBlackAndWhite")
        textField.placeholder = "Укажите новое имя для файла"
        textField.borderStyle = .roundedRect
        textField.layer.shadowColor = UIColor.lightGray.cgColor //цвет тени
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)  //смещение тени
        textField.layer.shadowRadius = 4  // радиус размытия тени
        textField.layer.shadowOpacity = 0.4 // прозрачность тени
        textField.layer.masksToBounds = false
        return textField
    }()
    
    init(viewModel: RenameFileViewModel) {
        self.renameFileViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        textField.text = renameFileViewModel.fileName
        if let image = renameFileViewModel.fileImage {
            setLeftImage(image: image)
        }
        setRightButton()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "Переименовать"
        view.addSubview(textField)
        view.addSubview(activityIndicatorRenameFile)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Готово",
            style: .plain,
            target: nil,
            action: #selector(renameFile))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setLeftImage(image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        containerView.addSubview(imageView)
        
        imageView.center = containerView.center
        textField.leftView = containerView
        textField.leftViewMode = .always
    }
    
    private func setRightButton() {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .gray
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(clearTextField), for: .touchUpInside)
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        containerView.addSubview(button)
        
        button.center = containerView.center
        textField.rightView = containerView
        textField.rightViewMode = .always
    }
    
    @objc private func clearTextField() {
        textField.text = nil
    }
    
    @objc private func renameFile() {
        guard let newFileName = textField.text, !newFileName.isEmpty else {
            let alertController = UIAlertController(title: "Ошибка", message: "Имя файла не может быть пустым", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ок", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        renameFileViewModel.fileName = newFileName
        DispatchQueue.main.async {
            self.activityIndicatorRenameFile.startAnimating()
        }
        renameFileViewModel.renameFile { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let newFileName):
                DispatchQueue.main.async {
                    self.activityIndicatorRenameFile.stopAnimating()
                    print("Имя файла изменено! \(newFileName) новое имя файла")
                    let alertController = UIAlertController(title: "Успешно", message: "Имя файла изменено", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ок", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            case .failure(let error):
                print("Ошибка переименования файла \(error.localizedDescription)")
                let alertController = UIAlertController(title: "Ошибка", message: "Не удалось изменить имя файла", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ок", style: .default)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension RenameFileViewController {
    private func setupConstraints() {
        textField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.height.equalTo(60)
        }
        activityIndicatorRenameFile.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorRenameFile.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-82)
            make.top.equalToSuperview().offset(60)
        }
    }
}
