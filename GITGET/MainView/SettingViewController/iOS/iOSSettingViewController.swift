//
//  iOSSettingViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import RxSwift
import RxCocoa
import SnapKit
import Then
import PanModal

protocol iOSSettingViewBindable {
    var howToUserButtonTapped: PublishRelay<Void> { get }
    var presentTutorialView: Driver<TutorialViewBindable> { get }
}

protocol SettingViewController {
    func bind(_ viewModel: iOSSettingViewBindable)
    func bind(_ viewModel: MacOSSettingViewBindable)
}

class iOSSettingViewController: UIViewController, SettingViewController {
    var disposeBag = DisposeBag()
    
    let titleLabel = UILabel()
    let howToUserButton = UIButton()
    let illustImagView = UIImageView(image: #imageLiteral(resourceName: "illust0"))
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attribute()
        layout()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewController = AboutViewController()
        let viewModel = AboutViewModel()
        viewController.bind(viewModel)
        self.presentPanModal(viewController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(_ viewModel: iOSSettingViewBindable) {
        self.disposeBag = DisposeBag()
        
        viewModel.presentTutorialView
            .drive(onNext: { [weak self] viewModel in
                let tutorialViewController = TutorialViewController()
                tutorialViewController.bind(viewModel)
                self?.present(tutorialViewController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        howToUserButton.rx.tap
            .bind(to: viewModel.howToUserButtonTapped)
            .disposed(by: disposeBag)
    }
    
    func bind(_ viewModel: MacOSSettingViewBindable) {}
    
    private func attribute() {
        view.backgroundColor = UIColor(named: "background")
        navigationController?.navigationBar.isHidden = true
        
        titleLabel.do {
            $0.text = "GitGet".localized
            $0.textColor = UIColor(named: "title")
            $0.font = .monospacedSystemFont(ofSize: 34, weight: .black)
            $0.numberOfLines = 1
        }
        
        howToUserButton.do {
            $0.setTitle("START".localized, for: .normal)
            $0.setTitleColor(UIColor(named: "button_title"), for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 20, weight: .bold)
            $0.backgroundColor = UIColor(named: "button")
            $0.layer.cornerRadius = 32
            $0.clipsToBounds = true
        }
    }
    
    private func layout() {
        [
            titleLabel,
            illustImagView,
            howToUserButton
        ].forEach {
            view.addSubview($0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaInsets.bottom).offset(60)
            $0.leading.equalToSuperview().offset(25)
        }
        
        illustImagView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-50)
        }
        
        howToUserButton.snp.makeConstraints {
            $0.top.equalTo(illustImagView.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(64)
        }
    }
}
