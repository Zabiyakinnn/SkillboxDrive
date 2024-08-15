//
//  TabBarViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 27.05.2024.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        setupVC()
        view.backgroundColor = .white
        view.tintColor = .blue
    }
    
    fileprivate func createNavController(for rootViewController: UIViewController,
                                         title: String,
                                         image: UIImage) -> UIViewController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        navController.navigationItem.title = title
        return navController
    }
    
    func setupVC() {
        viewControllers = [
            createNavController(for: ProfileViewController(), title: "Профиль", image: UIImage(systemName: "person")!),
            createNavController(for: LastUploadedFilesViewController(), title: "Последние", image: UIImage(systemName: "doc")!),
            createNavController(for: FilesViewController(), title: "Все файлы", image: UIImage(systemName: "archivebox")!)
        ]
    }
}
