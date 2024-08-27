//
//  NotificationUtils.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 21.08.2024.
//

import UIKit
import SnapKit

public final class NotificationUtils {
    
    static func showNoInternetConnectionView(on viewController: UIViewController) {
        
        let notificationView = UIView()
        notificationView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        notificationView.layer.cornerRadius = 10
        
        let labelNoInternet = UILabel()
        labelNoInternet.text = "Нет соеденения с интернетом"
        labelNoInternet.textColor = .white
        labelNoInternet.textAlignment = .center
        
        viewController.view.addSubview(notificationView)
        notificationView.addSubview(labelNoInternet)
        
        notificationView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(viewController.view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        labelNoInternet.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        notificationView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            notificationView.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.5, animations: {
                notificationView.alpha = 0
            }) { _ in
                notificationView.removeFromSuperview()
            }
        }
    }
    
    static func showDeliteFile(on viewController: UIViewController) {
        
        let notificationView = UIView()
        notificationView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        notificationView.layer.cornerRadius = 10
        
        let labelNoInternet = UILabel()
        labelNoInternet.text = "Файл удален"
        labelNoInternet.textColor = .white
        labelNoInternet.textAlignment = .center
        
        viewController.view.addSubview(notificationView)
        notificationView.addSubview(labelNoInternet)
        
        notificationView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(viewController.view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        labelNoInternet.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        notificationView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            notificationView.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.5, animations: {
                notificationView.alpha = 0
            }) { _ in
                notificationView.removeFromSuperview()
            }
        }
    }
}
