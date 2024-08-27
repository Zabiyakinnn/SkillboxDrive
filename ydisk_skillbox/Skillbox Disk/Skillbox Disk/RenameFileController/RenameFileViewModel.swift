//
//  RenameFileViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 27.08.2024.
//

import UIKit

class RenameFileViewModel {
    
    private var file: ItemList
    var fileName: String
    let fileImage: UIImage?
    var fileRenamed: ((String) -> Void)?
    
    
    init(file: ItemList, fileName: String, fileImage: UIImage?) {
        self.file = file
        self.fileName = fileName
        self.fileImage = fileImage
        
    }
    
    //    переименование изображения
    func renameFile(completion: @escaping (Result<String, Error>) -> Void?) {
        guard !fileName.isEmpty else {
            completion(.failure(NSError(domain: "Неверное имя", code: 400, userInfo: [NSLocalizedDescriptionKey: "Имя файла не может быть пустым"])))
            return
        }
            let fromPath = file.path ?? ""
            //      получаем формат файла
            let fileExtension = (fromPath as NSString).pathExtension
            let newFilePathExtension: String
            if fileExtension.isEmpty {
                //            если формат файла пустой
                newFilePathExtension = fileName
            } else {
                //            если формат файла не пустой, добавляем его если оно отсутствует в новом имени
                if fileName.hasSuffix(".\(fileExtension)") {
                    newFilePathExtension =  fileName
                } else {
                    newFilePathExtension = fileName + ".\(fileExtension)"
                }
            }
            //        новый путь с новым именем и расширением
            let toPath = (fromPath as NSString).deletingLastPathComponent + "/" + newFilePathExtension
            
            NetworkService.shared.renameFile(url: "https://cloud-api.yandex.net/v1/disk/resources/move", fromPath: fromPath, toPath: toPath) { result in
                switch result {
                case .success():
                    DispatchQueue.main.async {
                        if let existingDisk = CoreDataManager.shared.fetchDisk().first(where: { $0.path == fromPath }) {
                            print("Запись найденна обновление данных")
                            existingDisk.name = self.fileName
                            existingDisk.path = toPath
                            CoreDataManager.shared.appDelegate.saveContext()
                        }
                        self.fileRenamed?(self.fileName)
                    }
                    completion(.success(self.fileName))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}

