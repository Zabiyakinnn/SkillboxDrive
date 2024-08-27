//
//  NetworkManager.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 19.07.2024.
//


import UIKit

public final class NetworkService {
    
    static let shared = NetworkService()
    private var filesData: ItemList?
    var onProfileInfoReceived: ((Int, Int) -> Void)?
    
//Интернет запрос для получения данных в таблицу с разными URL
    func fetchData(endpoint: String, queryItems: [URLQueryItem], completion: @escaping (Result<Data, Error>) -> Void) {
        var components = URLComponents(string: endpoint)
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) else {
            completion(.failure(NSError(domain: "Токен не найден", code: 0, userInfo: nil)))
            return
        }
        request.httpMethod = "GET"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "InvalidResponce", code: 0, userInfo: nil)))
                return
            }
            guard (200...300).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: nil)))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
            }
        }
        task.resume()
    }
    
//Интернет запрос для откртия файла по path
    func openFile(with path: String, completion: @escaping (ItemList?) -> Void) {
        var components = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/resources")
        components?.queryItems = [URLQueryItem(name: "path", value: path)]
        
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) else { return }
        request.httpMethod = "GET"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        print("Request URL: \(url)")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error")
                return
            }
            if let data = data {
                do {
                    let newFiles = try JSONDecoder().decode(ItemList.self, from: data)
                    self.filesData = newFiles
                    completion(newFiles)
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }
        task.resume()
    }
    
//Интернет запрос для полученния данных профиля (свободное и занятое место на диске)
    func profileInfoData() {
        let components = URLComponents(string: "https://cloud-api.yandex.net/v1/disk/")
        
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) else { return }
        request.httpMethod = "GET"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        //        print("\(request)")
        //        print("TOKEN: ----- \(token)")
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server error")
                return
            }
            if let data = data {
                do {
                    let profileInfo = try JSONDecoder().decode(ProfileInfo.self, from: data)
                    DispatchQueue.main.async {
                        if let totalSpace = profileInfo.total_space,
                           let usedSpace = profileInfo.used_space {
                            let profileinfo = ProfileInfo(total_space: totalSpace, used_space: usedSpace)
                            self.onProfileInfoReceived?(totalSpace, usedSpace)
//                            print("Выполнен запрос на получение ифнормации о профиле \(profileinfo)")
                        } else {
                            print("Ошибка: Некорректные данные DiskResource")
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }
        task.resume()
    }
    
//Запрос на переименование файла
    func renameFile(url: String, fromPath: String, toPath: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "from", value: fromPath),
            URLQueryItem(name: "path", value: toPath)
        ]
        
        guard let finalURL = components?.url else {
            completion(.failure(NSError(domain: "Invalid URL components", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: finalURL)
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) else {
            completion(.failure(NSError(domain: "Токне не найден", code: 0, userInfo: nil)))
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No response", code: 0, userInfo: nil)))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let errorDescription = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                let serverError = NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                completion(.failure(serverError))
            }
        }
        task.resume()
    }
    
//Зарос на удаление файла
    func deleteFile(url: String, filePath: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "path", value: filePath)
        ]
        guard let finalURL = components?.url else {
            completion(.failure(NSError(domain: "Invalid URL components", code: 0, userInfo: nil)))
            return
        }
        var request = URLRequest(url: finalURL)
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKey.saveToken) else {
            completion(.failure(NSError(domain: "Токен не найден", code: 0, userInfo: nil)))
            return
        }
        request.httpMethod = "DELETE"
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No response", code: 0, userInfo: nil)))
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let errorDescription = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                let serverError = NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                completion(.failure(serverError))
            }
        }
        task.resume()
    }
}
