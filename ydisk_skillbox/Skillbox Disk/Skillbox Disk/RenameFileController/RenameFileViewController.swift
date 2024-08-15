//
//  RenameFileViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 20.07.2024.
//

import UIKit
import SnapKit

class RenameFileViewController: UIViewController {
    
    private var file: ItemList
    private var fileName: String
    private let fileImage: UIImage?
    
    private let activityIndicatorRenameFile: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Укажите новое имя для файла"
        textField.borderStyle = .roundedRect
        textField.layer.shadowColor = UIColor.lightGray.cgColor //цвет тени
        textField.layer.shadowOffset = CGSize(width: 0, height: 2)  //смещение тени
        textField.layer.shadowRadius = 4  // радиус размытия тени
        textField.layer.shadowOpacity = 0.4 // прозрачность тени
        textField.layer.masksToBounds = false
        return textField
    }()
    
    init(file: ItemList, fileName: String, fileImage: UIImage?) {
        self.file = file
        self.fileName = fileName
        self.fileImage = fileImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Переименовать"
        setupView()
        setupConstraints()
        textField.text = fileName
        if let image = fileImage {
            setLeftImage(image: image)
        }
        setRightButton()
    }
    
    private func setupView() {
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
        let fromPath = file.path
//      получаем формат файла
        let fileExtension = (fromPath! as NSString).pathExtension
        let newFilePathExtension: String
        if fileExtension.isEmpty {
//            если формат файла пустой
            newFilePathExtension = newFileName
        } else {
//            если формат файла не пустой, добавляем его если оно отсутствует в новом имени
            if newFileName.hasSuffix(".\(fileExtension)") {
                newFilePathExtension = newFileName
            } else {
                newFilePathExtension = newFileName + ".\(fileExtension)"
            }
        }
//        новый путь с новым именем и расширением
        let toPath = (fromPath! as NSString).deletingLastPathComponent + "/" + newFilePathExtension
        DispatchQueue.main.async {
            self.activityIndicatorRenameFile.startAnimating()
        }
        
        NetworkService.shared.renameFile(url: "https://cloud-api.yandex.net/v1/disk/resources/move", fromPath: fromPath!, toPath: toPath) { result in
            switch result {
            case .success:
                print("Имя файла изменено")
                if let existingDisk = CoreDataManager.shared.fetchDisk().first(where: { $0.path == fromPath }) {
                    existingDisk.name = newFileName
                    existingDisk.path = toPath
                    CoreDataManager.shared.fetchDisk()
                }
                DispatchQueue.main.async {
                    self.activityIndicatorRenameFile.stopAnimating()
                    let alertController = UIAlertController(title: "Успешно", message: "Имя файла изменено", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ок", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            case .failure(let error):
                print("Ошибка переименования файла - \(error)")
                DispatchQueue.main.async {
                    self.activityIndicatorRenameFile.stopAnimating()
                    let alertController = UIAlertController(title: "Ошибка", message: "Не удалось изменить имя файла", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ок", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
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
