//
//  OpenFilesViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 14.06.2024.
//

import UIKit
import SnapKit

class OpenFilesViewController: UIViewController {
    
    private let file: ItemList
    let filesCell = "filesCell"
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(FilesCell.self, forCellReuseIdentifier: "filesCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    init(fileList: ItemList) {
        self.file = fileList
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
        self.title = "\(file.name ?? "Название файла")"
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
        guard let items = file._embedded?.items else {
            return cell ?? UITableViewCell()
        }
        
        let currentFile = items[indexPath.row]
        cell?.configure(currentFile)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return file._embedded?.items.count ?? 0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}



