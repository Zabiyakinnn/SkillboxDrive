//
//  ProfileViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 30.08.2024.
//

import UIKit
import Network

class ProfileViewModel {
    
//    Передача модели данных на view и обновление нтерфейса
    var onProfileInfoUpdated: ((ProfileInfo) -> Void)?
//    Передача ошибки на view
    var onError: ((String) -> Void)?
    
//    Получение данных профиля из сети
    func fetchProfileInfo() {
        let networkService = NetworkService.shared
        networkService.onProfileInfoReceived = { [weak self] freeSpace, usedSpace in
            guard let self = self else { return }
            let profileInfo = ProfileInfo(total_space: freeSpace, used_space: usedSpace)
            self.saveProfileInfo(profileInfo)
            self.onProfileInfoUpdated?(profileInfo)
        }
        networkService.profileInfoData()
    }
    
//    Загрузка данных из Core Data
    func loadProfileInfo() {
        if let profileInfo = CoreDataManager.shared.fetchDiskProfileInfo().map({ disk in
            ProfileInfo(total_space: Int(disk.total_space), used_space: Int(disk.used_space))
        }).first {
            onProfileInfoUpdated?(profileInfo)
        } else {
            onError?("Данные не найдены")
        }
    }
//    Сохранение данных
    func saveProfileInfo(_ profileInfo: ProfileInfo) {
        CoreDataManager.shared.saveProfileInfo(profileInfo: profileInfo)
    }
//    Проверка интернет соеденения
    func checkNetworkConnection() {
        let monitor = NWPathMonitor() //монитор отслеживания сети
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
//                    если есть соеденение с интернетом
                    self?.fetchProfileInfo()
                } else {
                    self?.loadProfileInfo()
                    self?.onError?("Нет соединения с интернетом. Повторите попытку позже.")
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
}
