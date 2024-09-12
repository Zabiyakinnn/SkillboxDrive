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
    
    private var publishedFileViewModel = PublishedFileViewModel()
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
        publishedFileViewModel.checkNetworkConnection()
        setupBindings()
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
        tableView.refreshControl = myRefreshControl
    }
    
    private func setupBindings() {
        publishedFileViewModel.onLoadingStatus = { [weak self] in
            guard let self = self else { return }
            if self.publishedFileViewModel.isLoading {
                self.activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
        
        activityIndicator.startAnimating()
        publishedFileViewModel.onPublischedFile = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        }
        
        publishedFileViewModel.onError = { [weak self] error in
            guard let self = self else { return }
            print("Error publichedFile\(error)")
            showNoInternetConnectionView()
        }
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.activityIndicator.stopAnimating()
            self.myRefreshControl.isHidden = true
            sender.endRefreshing()
        }
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
        publishedFileViewModel.numberOfRows(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        извлекаем ячейку с помощью идентификатора
        guard let cell = tableView.dequeueReusableCell(withIdentifier: publishedFileCell, for: indexPath) as? PublishedFileCell else {
            return UITableViewCell()
        }
//        проверяем наличие данных
        guard let items = publishedFileViewModel.filesData?.items, items.count > indexPath.row else {
            return UITableViewCell()
        }
        cell.onDeleteTapped = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.publishedFileViewModel.deleteFile(at: indexPath)
//                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadData()
                self.showDeleteFile()
            }
        }
        cell.viewController = self
        let currentFile = items[indexPath.row]
        cell.configure(currentFile)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = publishedFileViewModel.filesData?.items, items.count > indexPath.row else {
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
                            self?.publishedFileViewModel.checkNetworkConnection()
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



