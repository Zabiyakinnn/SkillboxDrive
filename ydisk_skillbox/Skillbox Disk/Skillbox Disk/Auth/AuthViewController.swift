//
//  AuthViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit
import WebKit
import SnapKit

/// с помощью протокола передаем токен
protocol AuthViewControllerDelegate: AnyObject {
    func handleTokenChanged(token: String)
}

final class AuthViewController: UIViewController {
    
    private lazy var scheme = "myFile"
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let webView = WKWebView()
    
    private var request: URLRequest? {
        guard var components = URLComponents(string: "https://oauth.yandex.ru/authorize") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "client_id", value: "d4464c6a218b417ea7bcba2985a2e669")
        ]
        guard let url = components.url else { return nil }
        return URLRequest(url: url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Info"
        view.addSubview(webView)
        setupeConstraint()
        webView.navigationDelegate = self
        guard let request = request else { return }
        webView.load(request) 
    }
    
}

extension AuthViewController {
    private func setupeConstraint() {
        webView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension AuthViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
           url.scheme == scheme {
            let targetString = url.absoluteString.replacingOccurrences(of: "#", with: "?")
            guard let components = URLComponents(string: targetString) else { return }
            
            let token = components.queryItems?.first(where: { $0.name == "access_token"})?.value
            
            if let token =  token {
                delegate?.handleTokenChanged(token: token)
            }
            
            dismiss(animated: true, completion: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

