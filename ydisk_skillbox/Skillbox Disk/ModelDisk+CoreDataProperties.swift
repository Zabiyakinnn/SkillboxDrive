//
//  ModelDisk+CoreDataProperties.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 09.08.2024.
//
//

import Foundation
import CoreData

@objc(ModelDisk)
public class ModelDisk: NSManagedObject {}

extension ModelDisk {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ModelDisk> {
        return NSFetchRequest<ModelDisk>(entityName: "ModelDisk")
    }

    @NSManaged public var name: String?
    @NSManaged public var preview: String?
    @NSManaged public var created: String?
    @NSManaged public var size: Int64
    @NSManaged public var mime_type: String?
    @NSManaged public var path: String?
//    @NSManaged public var total_space: Int
//    @NSManaged public var used_space: Int
}

extension ModelDisk : Identifiable {}
