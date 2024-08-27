//
//  DiskResponse.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 31.05.2024.
//

import Foundation

struct ItemList: Codable {
    let _embedded: Embedded?
    let name: String?
    let preview: String?
    let created: String?
    let size: Int64?
    let path: String?
    let mime_type: String?
    let type: String?
    let sizes: [Size]?
    let href: String?
    let file: String?
}

struct Embedded: Codable {
    let items: [Item]
}

struct Item: Codable {
    let name: String?
    let preview: String?
    let created: String?
    let size: Int64?
    let path: String?
    let mime_type: String?
    let type: String?
}

struct Size: Codable {
    let url: String?
    let name: String?
}

struct DiskResponce: Codable {
    var items: [Items]?
}

struct Items: Codable {
    let name: String?
    let preview: String?
    let created: String?
    let size: Int64?
    let path: String?
    let mime_type: String?
    let resource_id: String?
}

struct ProfileInfo: Codable {
    let total_space: Int?
    let used_space: Int?
}
    



