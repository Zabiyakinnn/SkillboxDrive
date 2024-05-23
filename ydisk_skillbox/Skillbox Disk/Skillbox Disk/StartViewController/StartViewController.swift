//
//  ViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit
import SnapKit

class StartViewController: UIViewController {
    
    private var viewModel = StartViewModel()
    
    private lazy var buttonEnter: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.backgroundColor = .blue
        button.tintColor = .white
        button.setTitle("Войти", for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(enterButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var myLogoImage: UIImageView = {
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = viewModel.logoImage
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupeView()
    }
    
    private func setupeView() {
        view.addSubview(buttonEnter)
        view.addSubview(myLogoImage)
        setupeConstraint()
    }
    
    @objc func enterButton() {
        let infoVC = InfoViewController()
        present(infoVC, animated: true, completion: nil)
    }
}
extension StartViewController {
    private func setupeConstraint() {
        buttonEnter.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(720)
            make.width.equalTo(320)
            make.height.equalTo(50)
        }
        myLogoImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(271.05)
            make.height.equalTo(168)
            make.width.equalTo(196)
        }
    }
}

