//
//  SettingViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then
import StoreKit
import MessageUI
import SafariServices

protocol SettingViewBindable {
    var buttonAction: Signal<SettingMenu> { get }
    var buttonTapped: PublishRelay<SettingMenu> { get }
}

class SettingViewController: UIViewController {
    var disposeBag = DisposeBag()
    
    let titleLabel = UILabel()
    let howToUserButton = UIButton()
    
    let illustImagView = UIImageView(image: #imageLiteral(resourceName: "illust0"))
    
    let aboutLabel = UILabel()
    let ratingButton = UIButton()
    let sendMailButton = UIButton()
    let gitHubButton = UIButton()
    let linkedinButton = UIButton()
    let instagramButton = UIButton()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attribute()
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(_ viewModel: SettingViewBindable) {
        self.disposeBag = DisposeBag()
        viewModel.buttonAction
            .emit(to: self.rx.buttonAction)
            .disposed(by: disposeBag)
        
        howToUserButton.rx.tap
            .map { SettingMenu.howToUse }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
        
        ratingButton.rx.tap
            .map { SettingMenu.rating }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
        
        sendMailButton.rx.tap
            .map { SettingMenu.sendMail }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
        
        gitHubButton.rx.tap
            .map { SettingMenu.gitHub }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
        
        linkedinButton.rx.tap
            .map { SettingMenu.linkedin }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
        
        instagramButton.rx.tap
            .map { SettingMenu.instagram }
            .bind(to: viewModel.buttonTapped)
            .disposed(by: disposeBag)
    }
    
    func attribute() {
        view.backgroundColor = .white
        
        titleLabel.do {
            $0.text = "GitGet"
            $0.textColor = .black
            $0.font = .monospacedSystemFont(ofSize: 34, weight: .black)
            $0.numberOfLines = 1
        }
        
        howToUserButton.do {
            $0.setTitle("START", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 20, weight: .bold)
            $0.backgroundColor = UIColor(named: "button")
            $0.layer.cornerRadius = 10
            $0.clipsToBounds = true
        }
        
        aboutLabel.do {
            $0.text = "About"
            $0.textColor = .lightGray
            $0.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
            $0.numberOfLines = 1
        }
        
        ratingButton.do {
            $0.setTitle("Rate GitGet", for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
            $0.setTitleColor(.darkGray, for: .normal)
        }
        
        sendMailButton.do {
            $0.setTitle("Support", for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
            $0.setTitleColor(.darkGray, for: .normal)
        }
        
        gitHubButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_github"), for: .normal)
        }
        
        linkedinButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_linkedin"), for: .normal)
        }
        
        instagramButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_instagram"), for: .normal)
        }
    }
    
    func layout() {
        [
            titleLabel,
            illustImagView,
            howToUserButton,
            aboutLabel,
            ratingButton,
            sendMailButton,
            gitHubButton, linkedinButton, instagramButton
        ].forEach {
            view.addSubview($0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaInsets.bottom).offset(120)
            $0.leading.equalToSuperview().offset(25)
        }
        
        howToUserButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(25)
            $0.height.equalTo(72)
        }
        
        illustImagView.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-50)
            $0.leading.equalToSuperview().offset(78)
            $0.width.equalTo(304)
            $0.height.equalTo(355)
        }
        
        gitHubButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaInsets.bottom).offset(-80)
            $0.leading.equalToSuperview().offset(25)
            $0.width.height.equalTo(30)
        }
        
        linkedinButton.snp.makeConstraints {
            $0.centerY.equalTo(gitHubButton)
            $0.leading.equalTo(gitHubButton.snp.trailing).offset(12)
            $0.width.height.equalTo(30)
        }
        
        instagramButton.snp.makeConstraints {
            $0.centerY.equalTo(gitHubButton)
            $0.leading.equalTo(linkedinButton.snp.trailing).offset(12)
            $0.width.height.equalTo(30)
        }
        
        sendMailButton.snp.makeConstraints {
            $0.bottom.equalTo(gitHubButton.snp.top).offset(-24)
            $0.leading.equalToSuperview().offset(25)
        }
        
        ratingButton.snp.makeConstraints {
            $0.bottom.equalTo(sendMailButton.snp.top).offset(-16)
            $0.leading.equalToSuperview().offset(25)
        }
        
        aboutLabel.snp.makeConstraints {
            $0.bottom.equalTo(ratingButton.snp.top).offset(-21)
            $0.leading.equalToSuperview().offset(25)
        }
    }
}

extension Reactive where Base: SettingViewController {
    var buttonAction: Binder<SettingMenu> {
        return Binder(base) { base, menu in
            switch menu {
            case .howToUse: return presentTutorial()
            case .rating: return requestReview()
            case .sendMail: return setEmail()
            case .gitHub: return goToGitHub()
            case .linkedin: return goToLinkedIn()
            case .instagram: return goToInstagram()
            }
        }
    }
    
    func presentTutorial() {
        let viewController = TutorialViewController()
        let viewModel = TutorialViewModel()
        viewController.bind(viewModel)
        
        base.present(viewController, animated: true, completion: nil)
    }
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func setEmail() {
        let userSystemVersion = UIDevice.current.systemVersion
        let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = base
        
        mailComposeViewController.do {
            $0.setToRecipients([SystemConstants.Email.emailAddress])
            $0.setSubject(SystemConstants.Email.subject)
            $0.setMessageBody(String(format: SystemConstants.Email.body, userSystemVersion, userAppVersion as! CVarArg), isHTML: false)
        }
        
        if MFMailComposeViewController.canSendMail() {
            base.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func goToGitHub() {
        guard let directUrl:URL = URL(string: SystemConstants.SNS.github) else { return }
        UIApplication.shared.open(directUrl, options: [:], completionHandler: { result in
            if !result {
                base.openSafariView(for: SystemConstants.SNS.github)
            }
        })
    }
    
    func goToLinkedIn() {
        guard let directUrl:URL = URL(string: SystemConstants.SNS.linkedinDirect) else { return }
        UIApplication.shared.open(directUrl, options: [:], completionHandler: { result in
            if !result {
                base.openSafariView(for: SystemConstants.SNS.linkedin)
            }
        })
    }
    
    func goToInstagram() {
        guard let directUrl:URL = URL(string: SystemConstants.SNS.instagramDirect) else { return }
        UIApplication.shared.open(directUrl, options: [:], completionHandler: { result in
            if !result {
                base.openSafariView(for: SystemConstants.SNS.instagram)
            }
        })
    }
}

extension SettingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SettingViewController: SFSafariViewControllerDelegate {
    func openSafariView(for url:String) {
        guard let realUrl:URL = URL(string:url) else {return}
        let safariViewController:SFSafariViewController = SFSafariViewController(url: realUrl)
        safariViewController.delegate = self
        safariViewController.preferredControlTintColor = UIColor(named: "button")
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
