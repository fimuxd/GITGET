//
//  TutorialStepView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import RxSwift
import RxCocoa

protocol TutorialStepViewBindable {
    var step: Signal<Step> { get }
}

class TutorialStepView: UIView {
    var disposeBag = DisposeBag()
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        attribute()
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(_ viewModel: TutorialStepViewBindable) {
        self.disposeBag = DisposeBag()
        
        viewModel.step
            .map { $0.title }
            .emit(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.step
            .map { $0.description }
            .emit(to: descriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.step
            .map { $0.image }
            .emit(to: imageView.rx.image)
            .disposed(by: disposeBag)
    }
    
    func attribute() {
        backgroundColor = .white
        
        titleLabel.do {
            $0.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
            $0.textColor = .black
            $0.numberOfLines = 1
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        descriptionLabel.do {
            $0.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
            $0.textColor = .black
            $0.numberOfLines = 0
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.sizeToFit()
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func layout() {
        [titleLabel, descriptionLabel, imageView].forEach { addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(42)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(9)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-42)
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            $0.centerX.bottom.equalToSuperview()
        }
    }
}
