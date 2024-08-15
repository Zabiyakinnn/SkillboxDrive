//
//  NoFilesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 12.07.2024.
//

import UIKit

class NoFilesViewController: UIViewController {
    
    private let file: ItemList
    private let image = UIImage(named: "Group 9")
    
    private lazy var myLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Директория не содержит файлов"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var myImage: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.title = "\(file.name ?? "Название файла")"
        view.addSubview(myLabel)
        view.addSubview(myImage)
        setupeConstraint()
    }
    
    init(fileList: ItemList) {
        self.file = fileList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Set Constraint
extension NoFilesViewController {
    private func setupeConstraint() {
        myLabel.snp.makeConstraints { make in
            make.top.equalTo(480)
            make.centerX.equalToSuperview()
            make.width.equalTo(250)
            make.height.equalTo(70)
        }
        myImage.snp.makeConstraints { make in
            make.top.equalTo(380)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(90)
        }
    }
}
