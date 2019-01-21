//
//  LogInViewController2.swift
//  GITGET
//
//  Created by Bo-Young PARK on 21/01/2019.
//  Copyright © 2019 Bo-Young PARK. All rights reserved.
//

import RxSwift
import RxCocoa
import SnapKit
import Then

struct LogInViewModel: LogInViewBindable {
    let signUpButtonTapped = PublishRelay<Void>()
    let present: Driver<Void>
    
    init() {
        self.present = signUpButtonTapped
            .do(onNext: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            .asDriver(onErrorDriveWith: .empty())
    }
}

protocol LogInViewBindable {
    var signUpButtonTapped: PublishRelay<Void> { get }
    var present: Driver<Void> { get }
}

class LogInViewController2: UIViewController {
    let imageView = UIImageView(image: #imageLiteral(resourceName: "GitgetLogo"))
    let titleLabel = UILabel()
    let signInButton = UIButton()
    let noticeLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attribute()
        layout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(_ model: LogInViewBindable) {
        let disposeBag = DisposeBag()
        
        signInButton.rx.tap
            .bind(to: model.signUpButtonTapped)
            .disposed(by: disposeBag)

        model.present
            .drive(onNext: {
                self.present(OAuthWebViewController(), animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    func attribute() {
        self.view.backgroundColor = UIColor.init(displayP3Red: 246, green: 246, blue: 246, alpha: 1)
        
        self.titleLabel.do {
            $0.text = "Welcome to GITGET"
            $0.font = UIFont.init(name: "Menlo Bold", size: 12)
        }
        
        self.signInButton.do {
            $0.setImage(#imageLiteral(resourceName: "GitHub-Mark_White"), for: .normal)
            $0.setTitle("Sign in with GitHub", for: .normal)
            $0.backgroundColor = .black
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
            $0.titleLabel?.textColor = .white
            $0.layer.cornerRadius = 5
        }
        
        self.noticeLabel.do {
            $0.text = "You need to have a GitHub account to use the GITGET."
            $0.font = UIFont.systemFont(ofSize: 10)
        }
    }
    
    func layout() {
        signInButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.left.right.equalToSuperview().inset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(titleLabel.snp.top).offset(-50)
        }
        
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(100)
        }
        
        noticeLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-30)
        }
    }
}
