//
//  AuthViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit
import WebKit
import SnapKit

// с помощью протокола передаем токен
protocol AuthViewControllerDelegate: AnyObject {
    func handleTokenChanged(token: String)
}

final class AuthViewController: UIViewController {
    
    private let clientID = "52ca422fe65349ce9a3bf02799f11fca"
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let webView: WKWebView = {
        let webView = WKWebView()
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        setupeConstraint()
        clearWebViewCache()
        
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
    
    func clearWebViewCache() {
        let dataStore = WKWebsiteDataStore.default()
//        типы данных которые нужно очистить
        let websiteDataTypes = Set([WKWebsiteDataTypeCookies, WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
//        получение записей данных
        dataStore.fetchDataRecords(ofTypes: websiteDataTypes) { records in
//            проходим по каждоый записи и удаляем ее
            for record in records {
                dataStore.removeData(ofTypes: websiteDataTypes, for: [record], completionHandler: {})
            }
        }
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
                print("Token: ----------------- \(getToken)")
//              уведомлние делегата о получении токена
                delegate?.handleTokenChanged(token: getToken)
                dismiss(animated: true, completion: nil)
            }
        }
        decisionHandler(.allow)
    }
}
