//
//  UploadedFilesCell.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 05.06.2024.
//

import UIKit
import SnapKit
import SDWebImage

class UploadedFilesCell: UITableViewCell {
    
    private lazy var filesName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var sizeFile: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var createdFile: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var imageFile: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(filesName)
        contentView.addSubview(imageFile)
        contentView.addSubview(sizeFile)
        contentView.addSubview(createdFile)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ viewModel: UploadedFiles) {
        filesName.text = viewModel.name
    
        if let size = viewModel.size {
            let sizeInKilobytes = size / 1024
            let firstDigit = String(sizeInKilobytes).prefix(2)
            sizeFile.text = "\(firstDigit) кб"
        }
        
        let dateString = viewModel.created ?? ""
        let isoDateFormatter = ISO8601DateFormatter()
        
        if let date = isoDateFormatter.date(from: dateString) {
            let outputDateFormatter = DateFormatter()
            outputDateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
            let formattedDateString = outputDateFormatter.string(from: date)
            createdFile.text = formattedDateString
        } else {
            createdFile.text = "Дата не установленна"
        }
        
        
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) {
            let headers: [String: String] = ["Authorization": "OAuth \(token)"]
            let url = URL(string: viewModel.preview ?? "https://cm.author.today/content/2023/05/11/c12a9507922b470998f3d966e4e3264c.jpg")
            
            // Загрузка изображения с использованием токена аутентификации
            switch (viewModel.preview, viewModel.mime_type) {
            case (nil, "application/zip"):
                imageFile.image = UIImage(named: "zip")
            case(nil, "audio/mpeg"):
                imageFile.image = UIImage(named: "music")
            default:
                if let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) {
                    SDWebImageDownloader.shared.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
                    SDWebImageManager.shared.loadImage(
                        with: url,
                        options: [.highPriority, .handleCookies, .allowInvalidSSLCertificates],
                        context: nil,
                        progress: nil
                    ) { (image, data, error, cacheType, isFinished, imageUrl) in
                        if let error = error {
                            print("Произошла ошибка при загрузке изображения: \(error.localizedDescription)")
                        } else {
                            self.imageFile.image = image
                        }
                    }
                } else {
                    print("Отсутствие токена авторизации")
                }
            }
        }
    }
}
//MARK: - SetupeConstraints

extension UploadedFilesCell {
    private func setupConstraints() {
        imageFile.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left).inset(20)
            make.top.equalTo(contentView.snp.top).inset(10)
            make.bottom.equalTo(contentView.snp.bottom).inset(10)
            make.width.equalTo(60)
        }
        filesName.snp.makeConstraints { make in
            make.left.equalTo(imageFile.snp.left).inset(80)
            make.top.equalTo(contentView.snp.top).inset(10)
            make.width.equalTo(200)
        }
        sizeFile.snp.makeConstraints { make in
            make.left.equalTo(imageFile.snp.left).offset(80)
            make.bottom.equalTo(contentView.snp.bottom).offset(-10)
            make.width.equalTo(100)
        }
        createdFile.snp.makeConstraints { make in
            make.left.equalTo(sizeFile).offset(55)
            make.bottom.equalTo(contentView.snp.bottom).offset(-10)
            make.width.equalTo(150)
        }
    }

}
