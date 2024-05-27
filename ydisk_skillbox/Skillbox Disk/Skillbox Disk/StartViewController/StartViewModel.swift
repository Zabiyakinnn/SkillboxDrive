//
//  StartViewModel.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit

class StartViewModel {
    
    var logoImage: UIImage? {
        return UIImage(named: "logo")
    }
    
    func enterButtonTapped(navigationController: UINavigationController) {
        let infoVC = InfoViewController()
        navigationController.pushViewController(infoVC, animated: true)
    }
}
