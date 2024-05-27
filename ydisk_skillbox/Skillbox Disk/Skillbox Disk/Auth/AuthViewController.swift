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
    
//    private lazy var scheme = "https://oauth.yandex.ru/verification_code"
    private let clientID = "d4464c6a218b417ea7bcba2985a2e669"
    
    weak var delegate: AuthViewControllerDelegate?
    private let webView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        setupeConstraint()
        
        guard let request = request else { return }
        webView.load(request) 
        webView.navigationDelegate = self

    }
    
    private var request: URLRequest? {
        guard var components = URLComponents(string: "https://oauth.yandex.ru/authorize") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "client_id", value: "\(clientID)")
        ]
        guard let url = components.url else { return nil }
        return URLRequest(url: url)
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

//MARK: - WKNavigationDelegate
extension AuthViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let targetString = url.absoluteString.replacingOccurrences(of: "#", with: "?")
            guard let components = URLComponents(string: targetString) else { return }
            let getToken = components.queryItems?.first(where: {$0.name == "access_token"})?.value
            
            if let getToken = getToken {
                UserDefaults.standard.set(getToken, forKey: UserDefaultsKey.saveToken)
                print("Token: - \(getToken)")
            }
        }
        decisionHandler(.allow)
    }
    
}
