//
//  CoreDataManager.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 09.08.2024.
//

import UIKit
import CoreData

public final class CoreDataManager: NSObject {
    public static let shared = CoreDataManager()
    private override init() {}
    
    lazy var appDelegate: AppDelegate = {
        UIApplication.shared.delegate as! AppDelegate
    }()
    
    private var context: NSManagedObjectContext {
        appDelegate.persistentContainer.viewContext
    }
    //    MARK: - Model Disk
    //    Метод создания диска
    public func createDisk(name: String,
                           preview: String,
                           created: String,
                           size: Int64,
                           mime_type: String,
                           path: String,
                           resource_id: String
    ) {
        guard let diskEntityDescription = NSEntityDescription.entity(forEntityName: "ModelDisk", in: self.context) else {
//            print("Описание объекта не найдено")
            return
        }
//            print("Описание объекта найдено")
            let disk = ModelDisk(entity: diskEntityDescription, insertInto: self.context)
            disk.name = name
            disk.preview = preview
            disk.created = created
            disk.size = size
            disk.mime_type = mime_type
            disk.path = path
            disk.resource_id = resource_id
            self.appDelegate.saveContext()
        }
    
    //    Метод проверки существующего диска
    public func diskExists(withName name: String, withId resource_id: String) -> Bool {
        let fetchRequest: NSFetchRequest<ModelDisk> = ModelDisk.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND resource_id == %@", name, resource_id)
        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Ошибка получения: \(error.localizedDescription)")
            return false
        }
    }
    
    //    Загрузка диска Model Disk
    public func fetchDisk() -> [ModelDisk] {
        let fetchRequest: NSFetchRequest<ModelDisk> = ModelDisk.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch {
            print("Ошибка получения: \(error.localizedDescription)")
        }
        return []
    }
    
    //    Метод удаления диска
    public func deleteDisk() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ModelDisk")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Не удалось удалить записи: \(error)")
        }
    }
    
//    Метод удаления одной конкретной записи по path
    public func deleteFile(byPath path: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ModelDisk")
        fetchRequest.predicate = NSPredicate(format: "path == %@", path)
        
        do {
            if let fetchResults = try context.fetch(fetchRequest) as? [NSManagedObject], let objectToDelete = fetchResults.first {
                context.delete(objectToDelete)
                try context.save()
            } else {
                print("Запись для удаления не найдена")
            }
        } catch {
            print("Ошибка удаления записи \(error)")
        }
    }
    
    //    Метод сохранения диска массива DiskResponce
    func saveDisks(from response: DiskResponce) {
            guard let items = response.items else {
                print("Нет элементов для сохранения.")
                return
            }
            for item in items {
                if !self.diskExists(withName: item.name ?? "", withId: item.resource_id ?? "") {
                    let disk = ModelDisk(context: self.context)
                    disk.name = item.name ?? ""
                    disk.preview = item.preview ?? ""
                    disk.created = item.created ?? ""
                    disk.size = item.size ?? 0
                    disk.mime_type = item.mime_type ?? ""
                    disk.path = item.path ?? ""
                    disk.resource_id = item.resource_id ?? ""
                } else {
//                    print("Диск с таким именем уже существует")
                }
            }
        appDelegate.saveContext()
    }
    //    MARK: - Profile Info
    //    Метод сохранения ProfileInfo
    func saveProfileInfo(profileInfo: ProfileInfo) {
        DispatchQueue.main.async {
            guard let profileEntityDescription = NSEntityDescription.entity(forEntityName: "ModelProfileinfo", in: self.context) else {
                print("Описание объекта ProfileInfo не найдено")
                return
            }
    //            Создание объекта ModelProfileInfo и заполнение его данными
            let profile = ModelProfileinfo(entity: profileEntityDescription, insertInto: self.context)
            profile.total_space = Int64(profileInfo.total_space ?? 0)
            profile.used_space = Int64(profileInfo.used_space ?? 0)
    //            print("Сохраненные данные \(profile.total_space) ---- \(profile.used_space)")
            self.appDelegate.saveContext()
        }
    }
    //    Загрузка диска ModelProfileInfo
    public func fetchDiskProfileInfo() -> [ModelProfileinfo] {
        let fetchRequest: NSFetchRequest<ModelProfileinfo> = ModelProfileinfo.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
//            print("RESULT \(results)")
            return results
        } catch {
            print("Ошибка получения: \(error.localizedDescription)")
        }
        return []
    }
}
