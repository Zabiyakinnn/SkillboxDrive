//
//  OnboardingView.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit

class OnboardingView: UIView {
    
    private lazy var pageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var logoImageGroup: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(pageLabel)
        addSubview(logoImageGroup)
        setupeConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setPageLabelText(text: String) {
        pageLabel.text = text
    }
    
    public func setMyImage(image: UIImage) {
        logoImageGroup.image = image
    }
}

//MARK: - Set Constraint
extension OnboardingView {
    private func setupeConstraint() {
        pageLabel.snp.makeConstraints { make in
            make.top.equalTo(439)
            make.centerX.equalToSuperview()
            make.width.equalTo(250)
            make.height.equalTo(40)
        }
        logoImageGroup.snp.makeConstraints { make in
            make.top.equalTo(250)
            make.centerX.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(147)
        }
    }
}
