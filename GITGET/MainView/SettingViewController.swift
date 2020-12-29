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

protocol SettingViewBindable {
    var cellData: Driver<[SettingMenu]> { get }
    var requestRating: Signal<Void> { get }
    var sendEmail: Signal<Void> { get }
    var selectedRow: PublishRelay<Int> { get }
}

class SettingViewController: UIViewController {
    var disposeBag = DisposeBag()
    
    let tableView = UITableView()
    
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
        
        viewModel.cellData
            .drive(tableView.rx.items) { tv, row, data in
                let index = IndexPath(row: row, section: 0)
                let cell = tv.dequeueReusableCell(withIdentifier: String(describing: SettingTableViewCell.self), for: index) as! SettingTableViewCell
                cell.set(data: data)
                return cell
            }
            .disposed(by: disposeBag)
        
        viewModel.requestRating
            .emit(onNext: {
                SKStoreReviewController.requestReview()
            })
            .disposed(by: disposeBag)
        
        viewModel.sendEmail
            .emit(to: self.rx.sendEmail)
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .map { $0.row }
            .bind(to: viewModel.selectedRow)
            .disposed(by: disposeBag)
    }
    
    func attribute() {
        title = "GitHub Widget"
        view.backgroundColor = .white
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.do {
            $0.tableFooterView = UIView()
            $0.register(SettingTableViewCell.self, forCellReuseIdentifier: String(describing: SettingTableViewCell.self))
            $0.separatorStyle = .singleLine
            $0.rowHeight = UITableView.automaticDimension
            $0.estimatedRowHeight = 160
        }
    }
    
    func layout() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension Reactive where Base: SettingViewController {
    var sendEmail: Binder<Void> {
        return Binder(base) { base, _ in
            let userSystemVersion = UIDevice.current.systemVersion
            let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
            let mailComposeViewController = MFMailComposeViewController()
            
            mailComposeViewController.do {
                $0.setToRecipients([SystemConstants.Email.emailAddress])
                $0.setSubject(SystemConstants.Email.subject)
                $0.setMessageBody(String(format: SystemConstants.Email.body, userSystemVersion, userAppVersion as! CVarArg), isHTML: false)
            }
            
            if MFMailComposeViewController.canSendMail() {
                base.present(mailComposeViewController, animated: true, completion: nil)
            }
        }
    }
}

extension SettingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
