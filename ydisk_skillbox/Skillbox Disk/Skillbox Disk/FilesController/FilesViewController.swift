//
//  filesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 31.05.2024.
//

import UIKit
import SnapKit

class FilesViewController: UIViewController {
    
    private var filesData: ItemList?
    let filesCell = "filesCell"
    
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
        tableView.register(FilesCell.self, forCellReuseIdentifier: "filesCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Все файлы"
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.dataSource = self
        tableView.delegate = self
        setupeView()
    }
    
    private func setupeView() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        setupContraint()
        updateData()
        tableView.refreshControl = myRefreshControl
    }
    
    private func updateData() {
        activityIndicator.startAnimating()
        let queryItems = [
            URLQueryItem(name: "path", value: "/"),
            URLQueryItem(name: "limit", value: "300")
        ]
        NetworkService.shared.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources",
                                        queryItems: queryItems) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
            }
            switch result {
            case .success(let data):
                do {
                    let newFiles = try JSONDecoder().decode(ItemList.self, from: data)
                    self?.filesData = newFiles
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                } catch {
                    print("Error decoding \(error)")
                }
            case .failure(let error):
                print("Error \(error)")
            }
        }
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        updateData()
        activityIndicator.stopAnimating()
        sender.endRefreshing()
    }
}

//MARK: - SetupContraint
extension FilesViewController {
    private func setupContraint() {
        
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

//MARK: - UITableViewDataSource, UITableViewDelegate

extension FilesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesData?._embedded?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: filesCell, for: indexPath) as? FilesCell
        guard let items = filesData?._embedded?.items, items.count > indexPath.row else {
            return cell ?? UITableViewCell()
        }
        let currentFile = items[indexPath.row]
        cell?.configure(currentFile)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = filesData?._embedded?.items, items.count > indexPath.row else {
            return
        }
        let viewModel = items[indexPath.row]
        let pathFile = viewModel.path ?? ""
//        print("\(pathFile) получен")
        NetworkService.shared.openFile(with: pathFile) { [weak self] itemList in
            guard let itemList = itemList else {
                print("Не удалось получить itemList")
                return
            }
            DispatchQueue.main.async {
                if let items = itemList._embedded?.items, !items.isEmpty {
                    let openFileVC = OpenFilesViewController(fileList: itemList)
                    self?.navigationController?.pushViewController(openFileVC, animated: true)
                } else {
                    let mimeType = itemList.mime_type ?? ""
                    print("mimeType-------\(itemList.mime_type ?? "")")
                    print("type---------\(itemList.type ?? "")")
                    if let urlString = itemList.file, let url = URL(string: urlString) {
                        print("Получен URL: \(url)")
                        switch mimeType {
                        case "image/png", "image/svg", "image/jpeg", "image/heic":
                            let imageViewModel = ImageViewModel(item: itemList, imageURL: url)
                            let openImageVC = ImageViewController(viewModel: imageViewModel)
                            self?.navigationController?.pushViewController(openImageVC, animated: true)
                        case "application/pdf":
                            if UIApplication.shared.canOpenURL(url) {
                                let openPDFVC = PDFViewController(pdfURL: url, file: itemList)
                                self?.navigationController?.pushViewController(openPDFVC, animated: true)
                            } else {
                                print("Некорректный URL\(url)")
                            }
                        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-excel":
                            let openWKWebVC = WKWebViewController(docURL: url, file: itemList)
                            self?.navigationController?.pushViewController(openWKWebVC, animated: true)
                        default:
                            print("неизвестный тип данных - \(mimeType)")
                        }
                    } else {
                        let noFileVC = NoFilesViewController(fileList: itemList)
                        self?.navigationController?.pushViewController(noFileVC, animated: true)
                    }
                }
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

