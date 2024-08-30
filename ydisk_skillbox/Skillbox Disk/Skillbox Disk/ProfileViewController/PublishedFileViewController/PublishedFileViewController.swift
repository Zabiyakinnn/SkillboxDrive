//
//  PublishedFileViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 28.06.2024.
//

import UIKit
import SnapKit
import Network
import CoreData

final class PublishedFileViewController: UIViewController {
    
    private var publishedFileData: DiskResponce?
    var publishedFileCell = "publishedFileCell"
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(PublishedFileCell.self, forCellReuseIdentifier: "publishedFileCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var myRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        title = "Опубликованные файлы"
        tableView.dataSource = self
        tableView.delegate = self
        setupeView()
        setupConstraint()
    }
    
    private func setupeView() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        updateData()
        tableView.refreshControl = myRefreshControl
    }
    
    private func loadPublishedFile() {
        DispatchQueue.main.async {
            let savedDisk = CoreDataManager.shared.fetchDisk()
            let items = savedDisk.map { disk -> Items in
//                print("----------\(savedDisk)")
                return Items(name: disk.name,
                             preview: disk.preview,
                             created: disk.created,
                             size: disk.size,
                             path: disk.path,
                             mime_type: disk.mime_type,
                             resource_id: disk.resource_id)
            }
            self.publishedFileData = DiskResponce(items: items)
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
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
                    self.fetchDataFromNetwork()
                    print("Загрузка из сети")
                } else {
//                    нет подключения к интернету
                    self.loadPublishedFile()
//                    self?.tableView.reloadData()
                    print("Загрузка из core data")
                    self.showNoInternetConnectionView()
                }
                monitor.cancel()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func fetchDataFromNetwork() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        let queryItems = [
            URLQueryItem(name: "type", value: "dir, file"),
            URLQueryItem(name: "limit", value: "300")
        ]
        NetworkService.shared.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources/files",
                                        queryItems: queryItems) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let newFiles = try JSONDecoder().decode(DiskResponce.self, from: data)
                        self.publishedFileData = newFiles
                        DispatchQueue.main.async {
                            CoreDataManager.shared.saveDisks(from: newFiles)
//                            self.loadPublishedFile()
                            self.tableView.reloadData()
                        }
                    } catch {
                        print("Ошибка декодирования \(error)")
                    }
                case .failure(let error):
                    print("Error \(error)")
                    self.showAlert(title: "Ошибка сервера", message: "Повторите попытку позже")
                }
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        activityIndicator.stopAnimating()
        updateData()
        sender.endRefreshing()
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ок", style: .default)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.navigationController?.present(alertController, animated: true)
        }
    }
    
    private func showNoInternetConnectionView() {
        NotificationUtils.showNoInternetConnectionView(on: self)
    }
    
    private func showDeleteFile() {
        NotificationUtils.showDeliteFile(on: self)
    }
    
    private func deleteFile(at indexPath: IndexPath) {
        guard let item = publishedFileData?.items?[indexPath.row] else { return }
        let filePath = item.path
        
        NetworkService.shared.deleteFile(url: "https://cloud-api.yandex.net/v1/disk/resources", filePath: filePath ?? "") { result in
            switch result {
            case .success():
                DispatchQueue.main.async {
//              Удалить элемент и обновить таблицу
                    CoreDataManager.shared.deleteFile(byPath: filePath ?? "")
                    self.publishedFileData?.items?.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.showDeleteFile()
                }
            case .failure(let error):
                print("Не удалось удалить файл: \(error.localizedDescription)")
            }
        }
    }
}

//MARK: - SetupContraint
extension PublishedFileViewController {
    private func setupConstraint() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension PublishedFileViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publishedFileData?.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: publishedFileCell, for: indexPath) as? PublishedFileCell
        guard let items = publishedFileData?.items, items.count > indexPath.row else {
            return cell ?? UITableViewCell()
        }
        cell?.onDeleteTapped = { [weak self] in
            self?.deleteFile(at: indexPath)
        }
        cell?.viewController = self
        let currentFile = items[indexPath.row]
        cell?.configure(currentFile)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = publishedFileData?.items, items.count > indexPath.row else {
            return
        }
        let viewModel = items[indexPath.row]
        let pathFile = viewModel.path ?? ""
        
        NetworkService.shared.openFile(with: pathFile) { [weak self] itemList in
            guard let itemList = itemList else {
                return
            }
            DispatchQueue.main.async {
                let mimeType = itemList.mime_type ?? ""
                if let urlString = itemList.file, let url = URL(string: urlString) {
//                    print("Received URL: \(url)")
                    switch mimeType {
                    case "image/png", "image/svg", "image/jpeg", "image/heic":
                        let imageViewModel = ImageViewModel(item: itemList, imageURL: url)
                        let openImageVC = ImageViewController(viewModel: imageViewModel)
                        imageViewModel.fileRenamed = { [ weak self ] in
                            self?.updateData()
                            self?.tableView.reloadData()
                        }
                        self?.navigationController?.pushViewController(openImageVC, animated: true)
                    case "application/pdf":
//                        print("PDF URL: \(url)")
                        if UIApplication.shared.canOpenURL(url) {
                            let openPDFVC = PDFViewController(pdfURL: url, file: itemList)
                            self?.navigationController?.pushViewController(openPDFVC, animated: true)
                        } else {
                            print("Некорректный URL: \(url)")
                        }
                    case "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-excel":
                        let openWKWebViewVC = WKWebViewController(docURL: url, file: itemList)
                        self?.navigationController?.pushViewController(openWKWebViewVC, animated: true)
                    case "application/zip", "audio/mpeg", "video/mp4":
                        let unknownFileVC = UnknownFileViewController(fileList: itemList)
                        self?.navigationController?.pushViewController(unknownFileVC, animated: true)
                    default:
                        print("Неизвестный тип данных: \(mimeType)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}



