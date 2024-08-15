//
//  WKWebViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 18.07.2024.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController {
    
    var docURL: URL
    private let file: ItemList
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }()
    
    init(docURL: URL, file: ItemList) {
        self.docURL = docURL
        self.file = file
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        setupeView()
    }
    
    private func setupeView() {
        loadDocument()
        view.addSubview(activityIndicator)
        setupConstraint()
        title = "\(file.name ?? "Название файла")"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func loadDocument() {
        activityIndicator.startAnimating()
            webView.load(URLRequest(url: docURL))
            webView.navigationDelegate = self
    }
    
    private func setupConstraint() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
    }
}

extension WKWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
