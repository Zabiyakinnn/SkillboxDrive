//
//  LastUploadedFilesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 05.06.2024.
//

import UIKit
import Network

final class LastUploadedFilesViewController: UIViewController {
        
    private var lastUploadedFileViewModel = LastUploadedFilesViewModel()
    let uploadedFilesCell = "uploadedFilesCell"
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
        
    private lazy var myRefreshControl: UIRefreshControl = {
       let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        return refreshControl
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(UploadedFilesCell.self, forCellReuseIdentifier: "uploadedFilesCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Последние"
        lastUploadedFileViewModel.checkNetworkConnection()
        setupBindings()
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.delegate = self
        tableView.dataSource = self
        setupView()
        setupeConstraint()
    }
    
    private func setupView() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        tableView.refreshControl = myRefreshControl
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        lastUploadedFileViewModel.checkNetworkConnection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.activityIndicator.stopAnimating()
            sender.endRefreshing()
            self.myRefreshControl.isHidden = true
            self.tableView.reloadData()
        }
    }
    
    private func setupBindings() {
        
        lastUploadedFileViewModel.onLoadingStatus = { [weak self] in
            guard let self = self else { return }
            if self.lastUploadedFileViewModel.isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
        
        activityIndicator.startAnimating()
        lastUploadedFileViewModel.onLastUploadedFile = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        }
        
        lastUploadedFileViewModel.onError = { [weak self] error in
            guard let self = self else { return }
            print("\(error)")
            showNoInternetConnectionView()
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
}

//MARK: - UITableViewDataSource, UITableViewDelegate

extension LastUploadedFilesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lastUploadedFileViewModel.numberOfRows(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    Извлекаем ячейку с помощью идентификатора
        guard let cell = tableView.dequeueReusableCell(withIdentifier: uploadedFilesCell, for: indexPath) as? UploadedFilesCell else {
            return UITableViewCell()
        }
//        проверяем наличие данных
        guard let items = lastUploadedFileViewModel.filesData?.items, items.count > indexPath.row else {
            return UITableViewCell()
        }
        let currentFile = items[indexPath.row]
        cell.configure(currentFile)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = lastUploadedFileViewModel.filesData?.items, items.count > indexPath.row else {
            return
        }
        let viewModel = items[indexPath.row]
        let pathFile = viewModel.path ?? ""
//        print("Selected path: \(pathFile)")
        NetworkService.shared.openFile(with: pathFile) { [weak self] itemList in
            guard let itemList = itemList else {
                print("Не удалось получить itemList")
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
                        imageViewModel.fileRenamed = { [weak self] in
                            self?.lastUploadedFileViewModel.checkNetworkConnection()
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

//MARK: - SetupeConstraint
extension LastUploadedFilesViewController {
    private func setupeConstraint() {
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
