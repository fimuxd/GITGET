//
//  TutorialViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import RxSwift
import RxCocoa

protocol TutorialViewBindable {
    var stepOneViewModel: TutorialStepViewBindable { get }
    var stepTwoViewModel: TutorialStepViewBindable { get }
    var stepThreeViewModel: TutorialStepViewBindable { get }
    var stepFourViewModel: TutorialStepViewBindable { get }
}

class TutorialViewController: UIViewController {
    var disposeBag = DisposeBag()
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    let stepOneView = TutorialStepView()
    let stepTwoView = TutorialStepView()
    let stepThreeView = TutorialStepView()
    let stepFourView = TutorialStepView()
    let doneButton = UIButton(type: .close)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attribute()
        layout()
    }
    
    func bind(_ viewModel: TutorialViewBindable) {
        self.disposeBag = DisposeBag()
        
        stepOneView.bind(viewModel.stepOneViewModel)
        stepTwoView.bind(viewModel.stepTwoViewModel)
        stepThreeView.bind(viewModel.stepThreeViewModel)
        stepFourView.bind(viewModel.stepFourViewModel)
        
        doneButton.rx.tap
            .bind { self.dismiss(animated: true, completion: nil) }
            .disposed(by: disposeBag)
    }
    
    func attribute() {
        view.backgroundColor = .white
        
        scrollView.do {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        stackView.do {
            $0.axis = .vertical
            $0.spacing = 37
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func layout() {
        
        [scrollView, doneButton].forEach { view.addSubview($0) }
        scrollView.addSubview(stackView)
        [stepOneView, stepTwoView, stepThreeView, stepFourView]
            .forEach { stackView.addArrangedSubview($0) }
        
        doneButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(30)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(doneButton.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }
        
        stepOneView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(22)
            $0.leading.trailing.equalToSuperview()
        }

        stepTwoView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
        }

        stepThreeView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
        }

        stepFourView.snp.makeConstraints {
//            $0.top.equalTo(stepThreeView.snp.bottom).offset(37)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
}
