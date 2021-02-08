//
//  AboutViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/17/21.
//

import RxSwift
import RxCocoa
import StoreKit
import MessageUI
import SafariServices
import PanModal

protocol AboutViewBindable {
    var buttonAction: Signal<SettingMenu> { get }
    var buttonTapped: PublishRelay<SettingMenu> { get }
}

class AboutViewController: UIViewController {
    var disposeBag = DisposeBag()
    let tutorialViewController = TutorialViewController()
    let indicatorView = UIView()
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .shortForm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(_ viewModel: AboutViewBindable) {
        self.disposeBag = DisposeBag()
        let tutorialViewModel = TutorialViewModel()
        tutorialViewController.bind(tutorialViewModel)
        
        viewModel.buttonAction
            .emit(to: self.rx.buttonAction)
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
        view.backgroundColor = UIColor(named: "modal_background")
        
        indicatorView.do {
            $0.backgroundColor = UIColor(named: "indicator")
            $0.layer.cornerRadius = 5
            $0.clipsToBounds = true
        }
        
        aboutLabel.do {
            $0.text = "About".localized
            $0.textColor = UIColor(named: "about_label")
            $0.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
            $0.numberOfLines = 1
            $0.sizeToFit()
        }
        
        ratingButton.do {
            $0.setTitle("Rate GitGet".localized, for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
            $0.setTitleColor(UIColor(named: "title"), for: .normal)
        }
        
        sendMailButton.do {
            $0.setTitle("Support".localized, for: .normal)
            $0.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
            $0.setTitleColor(UIColor(named: "title"), for: .normal)
        }
        
        gitHubButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_github"), for: .normal)
        }
        
        linkedinButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_linkedin"), for: .normal)
            $0.sizeToFit()
        }
        
        instagramButton.do {
            $0.setImage(#imageLiteral(resourceName: "logo_instagram"), for: .normal)
        }
    }
    
    func layout() {
        [
            indicatorView,
            aboutLabel,
            ratingButton,
            sendMailButton,
            gitHubButton, linkedinButton, instagramButton
        ].forEach {
            view.addSubview($0)
        }
        
        indicatorView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(50)
            $0.height.equalTo(10)
        }
        
        aboutLabel.snp.makeConstraints {
            $0.top.equalTo(indicatorView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        ratingButton.snp.makeConstraints {
            $0.top.equalTo(aboutLabel.snp.bottom).offset(50)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(30)
        }
        
        sendMailButton.snp.makeConstraints {
            $0.top.equalTo(ratingButton.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(30)
        }
        
        linkedinButton.snp.makeConstraints {
            $0.top.equalTo(sendMailButton.snp.bottom).offset(36)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        
        gitHubButton.snp.makeConstraints {
            $0.centerY.equalTo(linkedinButton)
            $0.trailing.equalTo(linkedinButton.snp.leading).offset(-20)
            $0.width.height.equalTo(32)
            
        }
        
        instagramButton.snp.makeConstraints {
            $0.centerY.equalTo(linkedinButton)
            $0.leading.equalTo(linkedinButton.snp.trailing).offset(20)
            $0.width.height.equalTo(32)
        }
    }
}

extension AboutViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var longFormHeight: PanModalHeight {
        return .contentHeight(353)
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(107)
    }
    
    var anchorModalToLongForm: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 25
    }
    
    var panModalBackgroundColor: UIColor {
        return .clear
    }
    
    var allowsTapToDismiss: Bool {
        return false
    }
    
    var allowsDragToDismiss: Bool {
        return false
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var didBackgroundTapped: ((UIGestureRecognizer) -> Void)? {
        return { [weak tutorialViewController] _ in
            guard let viewController = tutorialViewController else { return }
            let viewModel = TutorialViewModel()
            viewController.bind(viewModel)
            self.present(viewController, animated: true)
        }
    }
}

extension Reactive where Base: AboutViewController {
    var buttonAction: Binder<SettingMenu> {
        return Binder(base) { base, menu in
            switch menu {
            case .rating: return requestReview()
            case .sendMail: return setEmail()
            case .gitHub: return goToGitHub()
            case .linkedin: return goToLinkedIn()
            case .instagram: return goToInstagram()
            }
        }
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

extension AboutViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension AboutViewController: SFSafariViewControllerDelegate {
    func openSafariView(for url:String) {
        guard let realUrl:URL = URL(string:url) else {return}
        let safariViewController:SFSafariViewController = SFSafariViewController(url: realUrl)
        safariViewController.delegate = self
        safariViewController.preferredControlTintColor = UIColor(named: "button")
        self.present(safariViewController, animated: true, completion: nil)
    }
}
