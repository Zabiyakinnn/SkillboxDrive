//
//  OpenFilesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 14.06.2024.
//

import UIKit
import SnapKit

class OpenFilesViewController: UIViewController {
    
    private let filesData: ItemList?
    let filesCell = "filesCell"
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(FilesCell.self, forCellReuseIdentifier: "filesCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    init(fileList: ItemList) {
        self.filesData = fileList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupeView()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "\(filesData?.name ?? "Название файла")"
    }
    
    private func setupeView() {
        view.addSubview(tableView)
        setupConstraint()
    }
}

//MARK: - SetupConstraint
extension OpenFilesViewController {

    private func setupConstraint() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

//MARK: - UITableViewDataSource
extension OpenFilesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: filesCell, for: indexPath) as? FilesCell
        guard let items = filesData?._embedded?.items else {
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
//                    print("mimeType-------\(itemList.mime_type ?? "")")
//                    print("type---------\(itemList.type ?? "")")
                    if let urlString = itemList.file, let url = URL(string: urlString) {
                        print("Получен URL: \(url)")
                        switch mimeType {
                        case "image/png", "image/svg", "image/jpeg", "image/heic":
                            let imageViewModel = ImageViewModel(item: itemList, imageURL: url)
                            let openImageVC = ImageViewController(viewModel: imageViewModel)
                            imageViewModel.fileDelete = { [weak self] in
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesData?._embedded?.items.count ?? 0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}



