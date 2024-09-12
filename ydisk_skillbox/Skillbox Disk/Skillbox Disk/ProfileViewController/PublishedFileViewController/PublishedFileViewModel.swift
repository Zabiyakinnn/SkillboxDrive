//
//  PublishedFileViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 07.09.2024.
//

import Foundation
import Network

class PublishedFileViewModel {
    
    //    данные полученные из сети
    private(set) var filesData: DiskResponce? {
        didSet {
            onPublischedFile?()
        }
    }
    //    состояние загрузки
    private(set) var isLoading: Bool = false {
        didSet {
            onLoadingStatus?()
        }
    }
    
//    обработчик событий для view
    var onError: ((String) -> Void)?
    var onPublischedFile: (() -> Void)?
    var onLoadingStatus: (() -> Void)?
    var onDeleteFile: (()-> Void)?
    
//    MARK: - Methods
//    проверка интернет соеденения
    func checkNetworkConnection() {
        let monitor = NWPathMonitor() //Монитор отслеживания состояния сети
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if path.status == .satisfied {
//                    если есть подключение к интернету
                    self.fetchPublishedFile()
                    print("Загрузка из сети")
                } else {
//                    нет подключения к интернету
                    self.loadPublishedFile()
                    self.onError?("Нет подключения к интернету. Повторите попытку позже")
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
    
//    загрузка данных из сети
    func fetchPublishedFile() {
        let queryItems = [
            URLQueryItem(name: "type", value: "dir, file"),
            URLQueryItem(name: "limit", value: "300")
        ]
        NetworkService.shared.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources/files",
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
                    self.onPublischedFile?()
                } catch {
                    print("Ошибка декодирования данных")
                }
            case .failure(let error):
                self.onError?("Ошибка - \(error)")
            }
        }
    }
//    загрузка данных из core data
    func loadPublishedFile() {
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
        onPublischedFile?()
    }
//    удаление файла
    func deleteFile(at indexPath: IndexPath) {
        guard let items = filesData?.items?[indexPath.row], let filePath = items.path else { return }
        
        NetworkService.shared.deleteFile(url: "https://cloud-api.yandex.net/v1/disk/resources", filePath: filePath) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success():
                DispatchQueue.main.async {
//          удалить элемент из локальных данных
                    self.filesData?.items?.remove(at: indexPath.row)
//          удалить файл из core data
                    CoreDataManager.shared.deleteFile(byPath: filePath)
//          уведомить view о том что файл был удален
                    self.onDeleteFile?()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onError?("Не удалось удалить файл: - \(error.localizedDescription)")
                }
            }
        }
    }

    func numberOfRows(_ section: Int) -> Int {
        filesData?.items?.count ?? 0
    }
}
