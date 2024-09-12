//
//  LastUploadedFilesViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 31.08.2024.
//

import UIKit
import Network

class LastUploadedFilesViewModel {
    
//    данные полученные из сети
    private(set) var filesData: DiskResponce? {
        didSet {
            onLastUploadedFile?()
        }
    }
//    состояние загрузки
    private(set) var isLoading: Bool = false {
        didSet {
            self.onLoadingStatus?()
        }
    }
   
//    обработчик событий для view
    var onError: ((String) -> Void)?
    var onLastUploadedFile: (() -> Void)?
    var onLoadingStatus: (() -> Void)?
    
    func numberOfRows(_ section: Int) -> Int {
        return filesData?.items?.count ?? 0
    }
    
//    MARK: - Methods
//    проверка интернет соеденения
    func checkNetworkConnection() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if path.status == .satisfied {
//                    если есть соеденение с интернетом
                    self.fetchUploadedFile()
                } else {
                    self.loadUploadedFile()
                    self.onError?("Нет подключения к интернету. Повторите попытку позже")
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
//    загрузка данных из сети
    func fetchUploadedFile() {
        let queryItems = [
            URLQueryItem(name: "media_type", value: "image, compressed, audio, document, text, video"),
            URLQueryItem(name: "limit", value: "300")
        ]
        let network = NetworkService.shared
        network.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources/last-uploaded",
                          queryItems: queryItems) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    let newFiles = try JSONDecoder().decode(DiskResponce.self, from: data)
                    self.filesData = newFiles
                    DispatchQueue.main.async {
                        CoreDataManager.shared.saveDisks(from: newFiles)
                    }
                    onLastUploadedFile?()
                } catch {
                    print("Ошибка декодирования данных")
                }
            case .failure(let error):
                self.onError?("Ошибка - \(error)")
            }
        }
    }
//    загрузка днных из coredata
    func loadUploadedFile() {
        let diskResponse = CoreDataManager.shared.fetchDisk().map({ disk -> Items in
            Items(
                name: disk.name,
                preview: disk.preview,
                created: disk.created,
                size: disk.size,
                path: disk.path,
                mime_type: disk.mime_type,
                resource_id: disk.resource_id
            )
        })
        self.filesData = DiskResponce(items: diskResponse)
        onLastUploadedFile?()
    }
}
