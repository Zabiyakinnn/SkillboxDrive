//
//  InfoViewController.swift
//  Skillbox Disk
//
//  Created by Дмитрий Забиякин on 16.05.2024.
//

import UIKit

class InfoViewController: UIViewController {
    
    static var current: InfoViewController?
    private var isFirst = false
    private var token = ""
    
    private lazy var scrollView: UIScrollView = {
       let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 3
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .blue
        return pageControl
    }()
    
    private lazy var buttonNext: UIButton = {
        let myButton = UIButton(type: .roundedRect)
        myButton.backgroundColor = .blue
        myButton.tintColor = .white
        myButton.setTitle("Далее", for: .normal)
        myButton.layer.cornerRadius = 10
        myButton.translatesAutoresizingMaskIntoConstraints = false
        myButton.addTarget(self, action: #selector(nextButton), for: .touchUpInside)
        return myButton
    }()
    
    private var slides = [OnboardingView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        InfoViewController.current = self
        setupView()
        setupeConstraint()
        setDelegate()
        
    }
    
    private func setupView() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(buttonNext)
        
        slides = createSlides()
        setupSlidesScrollView(slides: slides)
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirst {
            self.nextButton()
        } else {
            isFirst = false
        }
    }
    
    private func setDelegate() {
        scrollView.delegate = self
    }
    
    private func createSlides() -> [OnboardingView] {
        
        let firstOnboardingView = OnboardingView()
        firstOnboardingView.setPageLabelText(text: "Теперь все ваши документы в одном месте")
        
        if let imageOne = UIImage(named: "Group") {
            firstOnboardingView.setMyImage(image: imageOne)
        } else {
            print("Error 1")
        }
        
        let secondOnboardingView = OnboardingView()
        secondOnboardingView.setPageLabelText(text: "Доступ к файлам без интернета")
        
        if let imageTwo = UIImage(named: "Group 9") {
            secondOnboardingView.setMyImage(image: imageTwo)
        } else {
            print("Error 2")
        }
        
        let thirdOnboardingView = OnboardingView()
        thirdOnboardingView.setPageLabelText(text: "Делитесь вашими файлами с другми")
        
        if let imageThree = UIImage(named: "Group 11") {
            thirdOnboardingView.setMyImage(image: imageThree)
        } else {
            print("Error 3")
        }
        
        return [firstOnboardingView, secondOnboardingView, thirdOnboardingView]
        
    }
    
    private func setupSlidesScrollView(slides: [OnboardingView]) {
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count),
                                        height: 55)
        
        for i in 0..<slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i),
                                     y: 0,
                                     width: view.frame.width,
                                     height: view.frame.height)
            scrollView.addSubview(slides[i])
        }
    }
    
    @objc func nextButton() {
        openAuthViewController()
//        isFirst = true
//        guard !token.isEmpty else {
//            let authVC = AuthViewController()
//            authVC.delegate = self
//            present(authVC, animated: true)
//            return
//        }
    }
    func openAuthViewController() {
        guard !token.isEmpty else {
            let authVC = AuthViewController()
            authVC.delegate = self
            present(authVC, animated: true, completion: nil)
            return
        }
        
    }
    
}

//MARK: - UIScrollViewDelegate


extension InfoViewController: UIScrollViewDelegate {
     
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}

//MARK: - Set Constraint

extension InfoViewController {
    
    private func setupeConstraint() {
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-170)
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-30)
            make.height.equalTo(58)
        }
        buttonNext.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(720)
            make.width.equalTo(320)
            make.height.equalTo(50)
        }
    }
}

//MARK: - AuthViewControllerDelegate

extension InfoViewController: AuthViewControllerDelegate {
    func handleTokenChanged(token: String) {
        self.token = token
        print("token:- \(token)")
        openAuthViewController()
    }
}
