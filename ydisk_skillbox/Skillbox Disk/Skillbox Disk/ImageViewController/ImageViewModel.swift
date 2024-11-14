//
//  ImageViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 25.07.2024.
//

import Foundation
import SDWebImage

class ImageViewModel {
    
    let item: ItemList
    private var imageURL: URL
    
    var image: UIImage?
    var imageName: String?
    var formattedDate: String?
    
//  Предача информации об удалении изображения
    var fileDelete: (() -> Void)?
//  Успешная загрузка изображения
    var onImageLoaded: (() -> Void)?
//  Ошибка загрузки изображения
    var onImageLoadingError: ((String) -> Void)?
//  Успешное удаление изображения
//  var onImageDelete: (() -> Void)?
//  Ошибка удаления изображения
//  var onImageDeleteError: ((Error?) -> Void)?
    
    init(item: ItemList, imageURL: URL) {
        self.item = item
        self.imageURL = imageURL
        self.imageName = item.name
        self.formattedDate = item.created
        loadImage()
        formatDateString()
    }
//    Загрузка изображения
    private func loadImage() {
        // Используем только загрузку изображения без кеширования
        SDWebImageDownloader.shared.downloadImage(with: imageURL, options: [.highPriority], progress: nil) { [weak self] (image, data, error, finished) in
            guard let self = self else { return }
            
            // Проверка на ошибки загрузки изображения
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.onImageLoadingError?(error.localizedDescription)
                }
            } else if let image = image, finished {
                // Если изображение успешно загружено, используем его без кеширования
                self.image = image
                DispatchQueue.main.async {
                    self.onImageLoaded?()
                    print("Image loaded from network (no cache)")
                }
            }
        }
    }
    
    private func formatDateString() {
        let dateString = item.created ?? ""
        let isoDateFormatter = ISO8601DateFormatter()

        if let date = isoDateFormatter.date(from: dateString) {
            let outputDateFormatter = DateFormatter()
            outputDateFormatter.dateFormat = "dd.MM.yyyy"
            let formattedDateString = outputDateFormatter.string(from: date)
            self.formattedDate = formattedDateString
        }
    }
    
    func deleteFile(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let pathFile = item.path else {
            completion(.failure(NSError(domain: "Invalid path", code: 0, userInfo: nil)))
            return
        }

        NetworkService.shared.deleteFile(url: "https://cloud-api.yandex.net/v1/disk/resources", filePath: pathFile) { result in
            switch result {
            case .success():
                print("Файл удален")
                completion(.success(()))
            case .failure(let error):
                print("Ошибка удаления файла \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
