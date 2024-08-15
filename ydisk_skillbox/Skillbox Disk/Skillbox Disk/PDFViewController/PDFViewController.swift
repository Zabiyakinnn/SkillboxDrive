//
//  PDFViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.07.2024.
//

import UIKit
import PDFKit
import SnapKit

class PDFViewController: UIViewController {
    
    var pdfURL: URL
    private let file: ItemList
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = .lightGray
        progressView.progressTintColor = .blue
        return progressView
    }()

    init(pdfURL: URL, file: ItemList) {
        self.pdfURL = pdfURL
        self.file = file
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadPDFFIle()
        title = "\(file.name ?? "Название файла")"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    private func loadPDFFIle() {
        let pdfView = PDFView(frame: self.view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.frame = view.bounds
        self.view.addSubview(pdfView)
        
        progressView.center = view.center
        view.addSubview(progressView)
        
        let myPDFURLString = "\(pdfURL)"
        if let myURLPDF = URL(string: myPDFURLString) {
//            print("Загружаем PDF по URL: \(myURLPDF)")
            DispatchQueue.global(qos: .background).async {
                if let document = PDFDocument(url: myURLPDF) {
                    let pageCount = document.pageCount
                    for pageIndex in 0...pageCount {
                        Thread.sleep(forTimeInterval: 0.001)
                        let progress = Float(pageIndex + 1) / Float(pageCount)
                        DispatchQueue.main.async {
                            self.progressView.progress = progress
                        }
                    }
                    DispatchQueue.main.async {
                        pdfView.document = document
                        self.progressView.isHidden = true
//                        print("PDF документ успешно загружен")
                    }
                } else {
//                   print("Не удалось загрузить PDF документ")
                }
            }
        } else {
            print("Некорректный URL")
        }
    }
    
}



