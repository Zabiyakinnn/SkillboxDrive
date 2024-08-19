//
//  ProfileViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 06.06.2024.
//

import UIKit
import Charts
import Network

class ProfileViewController: UIViewController, ChartViewDelegate {
    
    var pieChart = PieChartView()
    private var profileInfo: ProfileInfo?
    
    private lazy var buttonFile: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.backgroundColor = UIColor(named: "ButtonBlackAndWhite")
        let arrowImage = UIImage(systemName: "arrow.turn.down.right")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        button.setImage(arrowImage, for: .normal)
        button.tintColor = UIColor(named: "TextBlackAndWhite")
        button.setTitle("Опубликованные файлы", for: .normal)
        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(enterButton), for: .touchUpInside)
//      тени для кнопки
        button.layer.shadowColor = UIColor.lightGray.cgColor //цвет тени
        button.layer.shadowOffset = CGSize(width: 0, height: 2)  //смещение тени
        button.layer.shadowRadius = 4  // радиус размытия тени
        button.layer.shadowOpacity = 0.4 // прозрачность тени
        button.layer.masksToBounds = false
        
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 150)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Профиль"
        view.backgroundColor = .systemBackground
        setupeView()
        pieChart.delegate = self
        pieChart.noDataText = "Загрузка данных..."
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        view.addSubview(pieChart)
        setupConstraint()
    }
    
    private func setupeView() {
        configureItems()
        view.addSubview(buttonFile)
        updateData()
    }
    
    func updatePieChart(totalSpace: Int, usedSpace: Int) {
        let freeSpaceGB = Double(totalSpace - usedSpace) / (1024 * 1024 * 1024)
        let usedSpaceGB = Double(usedSpace) / (1024 * 1024 * 1024)
        let totalSpaceGB = Double(totalSpace) / (1024 * 1024 * 1024)
        let entries = [
            PieChartDataEntry(value: Double(freeSpaceGB)),
            PieChartDataEntry(value: Double(usedSpaceGB))
        ]
        
        let set = PieChartDataSet(entries: entries)
        set.colors = [UIColor.lightGray, UIColor.systemBlue]
        set.drawValuesEnabled = false
        
        let data = PieChartData(dataSet: set)
        pieChart.data = data
        let centreTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 17),
            .foregroundColor: UIColor.black
        ]
        let centreText = NSAttributedString(string: "\(String(format: "%.2f", totalSpaceGB)) GB", attributes: centreTextAttributes)
        pieChart.centerAttributedText = centreText
        pieChart.rotationEnabled = false // отключение вращения
        pieChart.isUserInteractionEnabled = false // отключение нажатия на pieChart
        
        let legend = pieChart.legend
        legend.enabled = true
        legend.verticalAlignment = .bottom
        legend.horizontalAlignment = .center
        legend.orientation = .vertical
        legend.drawInside = false
        legend.font = UIFont.systemFont(ofSize: 16)
        legend.form = .square
        legend.formSize = 12
        legend.yEntrySpace = 10
        legend.yOffset = 4

        
        let gray = LegendEntry()
        gray.label = "\(String(format: "%.2f", freeSpaceGB)) GB - свободно"
        gray.form = .circle
        gray.formSize = 20
        gray.formLineWidth = 10
        gray.formColor = NSUIColor.lightGray

        let blue = LegendEntry()
        blue.label = "\(String(format: "%.2f", usedSpaceGB)) GB - занято"
        blue.form = .circle
        blue.formSize = 20
        blue.formLineWidth = 10
        blue.formColor = NSUIColor.systemBlue

        pieChart.legend.setCustom(entries: [gray, blue])
        pieChart.notifyDataSetChanged()
    }
    
    @objc func enterButton() {
        let publishedVC = PublishedFileViewController()
        navigationController?.pushViewController(publishedVC, animated: true)
    }
    
    private func loadProfileInfo() {
        DispatchQueue.main.async {
            let infoProfile = CoreDataManager.shared.fetchDiskProfileInfo()
            let item = infoProfile.map { disk in
                return ProfileInfo(
                    total_space: Int(disk.total_space),
                    used_space: Int(disk.used_space)
                )
            }
            if let firstItem = item.first {
                self.updatePieChart(totalSpace: firstItem.total_space ?? 0, usedSpace: firstItem.used_space ?? 0)
            } else {
                print("Данные не найдены")
            }
        }
    }
    
    private func updateData() {
        let monitor = NWPathMonitor() //Монитор отслеживания состояния сети
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if path.status == .satisfied {
//                    если есть подключение к интернету
                    self.fetchProfileInfo()
                    print("Загрузка из сети")
                } else {
//                    нет подключения к интернету
                    self.loadProfileInfo()
//                    self?.tableView.reloadData()
                    print("Загрузка из core data")
                    self.showAlert(title: "Нет соединения с интернетом", message: "Загрузка из core data")
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func fetchProfileInfo() {
        let networkService = NetworkService.shared
        networkService.onProfileInfoReceived = { [weak self] freeSpace, usedSpace in
            let saveProfileInfo = ProfileInfo(total_space: freeSpace, used_space: usedSpace)
            DispatchQueue.main.async {
                CoreDataManager.shared.saveProfileInfo(profileInfo: saveProfileInfo)
                self?.updatePieChart(totalSpace: freeSpace, usedSpace: usedSpace)
            }
        }
        networkService.profileInfoData()
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ок", style: .default)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.navigationController?.present(alertController, animated: true)
        }
    }
    
//MARK: - AlertController
    private func configureItems() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(moreButtonTapped))
        }
    
    @objc  func moreButtonTapped() {
        let actionSheet = UIAlertController(title: "Профиль",
                                            message: "",
                                            preferredStyle: .actionSheet)
        
        let passAction = UIAlertAction(title: "Выйти", style: .destructive) { [weak self] (_) in
            let alertController = UIAlertController(title: "Выход",
                                                    message: "Вы точно хотите выйти?",
                                                    preferredStyle: .alert)
            
            let yesButton = UIAlertAction(title: "Да", style: .default) { [weak self](_) in
                if let currentToken = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) {
                    print("Токен до удаления: \(currentToken)")
                } else {
                    print("Токен не найден")
                }
                
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.saveToken)
                UserDefaults.standard.synchronize()
                
                if UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) == nil {
                    print("Токен удален")
                } else {
                    print("Токен не удален")
                }
                
                let rootVC = StartViewController()
                let navController = UINavigationController(rootViewController: rootVC)
                if let window = self?.view.window {
                    window.rootViewController = navController
                    UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                        window.makeKeyAndVisible()
                    }, completion: nil)
                }
            }
            let noButton = UIAlertAction(title: "Нет", style: .destructive, handler: nil)
            yesButton.setValue(UIColor.blue, forKey: "titleTextColor")
            
            alertController.addAction(yesButton)
            alertController.addAction(noButton)
            self?.present(alertController, animated: true)
        }
        let destructiveAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        destructiveAction.setValue(UIColor.blue, forKey: "titleTextColor")
        actionSheet.addAction(passAction)
        actionSheet.addAction(destructiveAction)
        
        present(actionSheet, animated: true, completion: nil)
    }

}

// MARK: - SetupConstraint
extension ProfileViewController {
    private func setupConstraint() {
        pieChart.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(90)
            make.centerX.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(390)
        }
        buttonFile.snp.makeConstraints { make in
            make.top.equalTo(500)
            make.centerX.equalToSuperview()
            make.width.equalTo(370)
            make.height.equalTo(50)
        }
    }
}
