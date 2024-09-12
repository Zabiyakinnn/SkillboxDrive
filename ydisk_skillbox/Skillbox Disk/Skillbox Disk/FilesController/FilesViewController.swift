//
//  filesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 31.05.2024.
//

import UIKit
import SnapKit
import Network

final class FilesViewController: UIViewController {
    
    private var filesData: ItemList?
    private var filesViewModel = FilesViewModel()
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
        filesViewModel.updateData()
        self.navigationController?.navigationBar.tintColor = .lightGray
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.dataSource = self
        tableView.delegate = self
        setupeView()
        setupBindings()
        setupContraint()
    }
    
    private func setupeView() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        tableView.refreshControl = myRefreshControl
    }
    
    private func setupBindings() {
//        обновление состояния загрузки
        filesViewModel.onLoadingStatus = { [weak self] in
            guard let self = self else { return }
            if self.filesViewModel.isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
//        Обновление данных таблицы
        activityIndicator.startAnimating()
        filesViewModel.onFilesData = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
            }
        }
//        обработка ошибок
        filesViewModel.onError = { [weak self] error in
            guard let self = self else { return }
            print("\(error)")
            self.showAlert(title: "Ошибка", message: "\(error)")
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
    
    @objc private func refresh(sender: UIRefreshControl) {
        filesViewModel.updateData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.activityIndicator.stopAnimating()
            self.myRefreshControl.isHidden = true
            sender.endRefreshing()
        }
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
        return filesViewModel.numberOfRows(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    Извлекаем ячейку с помощью идентификатора
        guard let cell = tableView.dequeueReusableCell(withIdentifier: filesCell, for: indexPath) as? FilesCell else {
            return UITableViewCell()
        }
//        проверяем наличие данных
        guard let items = filesViewModel.filesData?._embedded?.items, items.count > indexPath.row else {
            return UITableViewCell()
        }
        let currentFile = items[indexPath.row]
        cell.configure(currentFile)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let items = filesViewModel.filesData?._embedded?.items, items.count > indexPath.row else {
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
//                    print("mimeType-------\(itemList.mime_type ?? "")")
//                    print("type---------\(itemList.type ?? "")")
                    if let urlString = itemList.file, let url = URL(string: urlString) {
                        print("Получен URL: \(url)")
                        switch mimeType {
                        case "image/png", "image/svg", "image/jpeg", "image/heic":
                            let imageViewModel = ImageViewModel(item: itemList, imageURL: url)
                            let openImageVC = ImageViewController(viewModel: imageViewModel)
                            imageViewModel.fileRenamed = { [weak self] in
                                self?.filesViewModel.updateData()
                                self?.tableView.reloadData()
                            }
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
                        case "application/zip", "audio/mpeg":
                            let unknownFileVC = UnknownFileViewController(fileList: itemList)
                            self?.navigationController?.pushViewController(unknownFileVC, animated: true)
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

