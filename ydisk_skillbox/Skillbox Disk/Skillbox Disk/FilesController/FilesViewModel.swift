//
//  FilesViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 30.08.2024.
//

import UIKit

class FilesViewModel {
    
//    Данные полученные из сети
    private(set) var filesData: ItemList? {
        didSet {
            self.onFilesData?()
        }
    }
//    Состояние загрузки
    private(set) var isLoading: Bool = false {
        didSet {
            self.onLoadingStatus?()
        }
    }
    
    func numberOfSection() -> Int {
        1
    }
    
    func numberOfRows(_ section: Int) -> Int {
        filesData?._embedded?.items.count ?? 0
    }
    
//   Обработчик событий для view
    var onFilesData: (() -> Void)?
    var onLoadingStatus: (() -> Void)?
    var onError: ((Error) -> Void)?
    
//    MARK: Methods
    
    func updateData() {
        self.isLoading = true
        let queryItems = [
            URLQueryItem(name: "path", value: "/"),
            URLQueryItem(name: "limit", value: "300")
        ]
        NetworkService.shared.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources",
                                        queryItems: queryItems) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            switch result {
            case .success(let data):
                do {
                    let newFiles = try JSONDecoder().decode(ItemList.self, from: data)
                    self?.filesData = newFiles
                } catch {
                    self?.onError?(error)
                }
            case .failure(let error):
                self?.onError?(error)
            }
        }
    }
}
