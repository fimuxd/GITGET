//
//  TipJarViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 27/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit

class TipJarViewController: UIViewController {

    let rowTitles:[String] = ["Energy bar".localized,
                              "A Cup of Coffee".localized,
                              "Burger and Fries".localized]
    let rowSubtitles:[String] = [" $0.99".localized,
                                 " $4.99".localized,
                                 " $9.99".localized]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        IAPHandler.shared.fetchAvailableProducts()
        IAPHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let strongSelf = self else{ return }
            if type == .purchased {
                let alertView = UIAlertController(title: "", message: type.message(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                    
                })
                alertView.addAction(action)
                strongSelf.present(alertView, animated: true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goToGitHubAction(_ sender: UIButton) {
        self.openSafariViewOf(url: "https://github.com/fimuxd")
    }
    
    @IBAction func goToFacebookAction(_ sender: UIButton) {
        guard let directUrl:URL = URL(string: "fb://profile?app_scoped_user_id=FIMUXD") else {return}
        UIApplication.shared.open(directUrl, options: [:], completionHandler: { (result) in
            if !result {
                self.openSafariViewOf(url: "https://www.facebook.com/FIMUXD")
            }
        })
    }
    
    @IBAction func goToLinkedInAction(_ sender: UIButton) {
        guard let directUrl:URL = URL(string: "linkedin://profile/parkboyoung") else {return}
        UIApplication.shared.open(directUrl, options: [:], completionHandler: { (result) in
            if !result {
                self.openSafariViewOf(url: "https://www.linkedin.com/in/parkboyoung")
            }
        })
    }
    
    func openSafariViewOf(url:String) {
        guard let realUrl:URL = URL(string:url) else {return}
        let safariViewController:SFSafariViewController = SFSafariViewController(url: realUrl)
        safariViewController.delegate = self
        safariViewController.preferredControlTintColor = UIColor(red: 0.137, green: 0.604, blue: 0.231, alpha: 1)
        self.present(safariViewController, animated: true, completion: nil)
    }
}

//MARK:- UITableViewDataSource & Delegate
extension TipJarViewController:UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return """
        CHOOSE DONATION PLAN
        Don't worry. All services of GITGET is free. You don't have to pay to use the app.
        """.localized
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.text = """
        CHOOSE DONATION PLAN
        Don't worry. All services of GITGET is free. You don't have to pay to use the app.
        """.localized
    }
    
    // TODO: 추후에 총 기부액 표시기능 넣기
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        let donatedAmount = "0.00"
//        return String(format: NSLocalizedString("Total donated amount: $%@", comment: ""),donatedAmount)
        return ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "donationCell") as! CustomTableViewCell
        
        cell.donationTitleLabel.text = self.rowTitles[indexPath.row]
        cell.donationPriceLabel.text = self.rowSubtitles[indexPath.row]
        cell.donationImageView.image = UIImage(named: "donation\(indexPath.row)")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        IAPHandler.shared.purchaseMyProduct(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
}

//MARK:- SafariService
extension TipJarViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
