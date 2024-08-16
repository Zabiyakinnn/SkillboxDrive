//
//  LastUploadedFilesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 05.06.2024.
//

import UIKit

class LastUploadedFilesViewController: UIViewController {
        
    private var filesData: DiskUploaded?
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
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.delegate = self
        tableView.dataSource = self
        setupView()
    }
    
    
    private func setupView() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        setupeConstraint()
        updateData()
        tableView.refreshControl = myRefreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        DispatchQueue.main.async {
            self.updateData()
        activityIndicator.stopAnimating()

//        }
    }
    
    @objc private func refresh(sender: UIRefreshControl) {
        updateData()
        activityIndicator.stopAnimating()
        sender.endRefreshing()
    }
    
    
    private func updateData() {
        activityIndicator.startAnimating()
        let queryItems = [
            URLQueryItem(name: "media_type", value: "image, compressed, audio, document, text, video"),
            URLQueryItem(name: "limit", value: "300")
        ]
        NetworkService.shared.fetchData(endpoint: "https://cloud-api.yandex.net/v1/disk/resources/last-uploaded",
                                        queryItems: queryItems) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
            }
            switch result {
            case .success(let data):
                do {
                    let newFiles = try JSONDecoder().decode(DiskUploaded.self, from: data)
                    self?.filesData = newFiles
                    DispatchQueue.main.async {
                        if self?.myRefreshControl.isRefreshing == true {
                            self?.myRefreshControl.endRefreshing()
                        }
                        self?.tableView.reloadData()
                    }
                } catch {
                    print("Error decoding \(error)")
                }
            case .failure(let error):
                print("Error \(error)")
                DispatchQueue.main.async {
                    if self?.myRefreshControl.isRefreshing == true {
                        self?.myRefreshControl.endRefreshing()
                    }
                }
            }
        }
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

//MARK: - UITableViewDataSource, UITableViewDelegate

extension LastUploadedFilesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesData?.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = filesData?.items, items.count > indexPath.row else {
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
                    case "application/zip", "audio/mpeg":
                        let unknownFileVC = UnknownFileViewController(fileList: itemList)
                        self?.navigationController?.pushViewController(unknownFileVC, animated: true)
                    default:
                        print("Неизвестный тип данных: \(mimeType)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: uploadedFilesCell, for: indexPath) as? UploadedFilesCell
        guard let items = filesData?.items, items.count > indexPath.row else {
            return cell ?? UITableViewCell()
        }
        let currentFile = items[indexPath.row]
        cell?.configure(currentFile)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
