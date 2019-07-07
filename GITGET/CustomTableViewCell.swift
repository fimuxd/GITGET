//
//  CustomTableViewCell.swift
//  GITGET
//
//  Created by Bo-Young PARK on 05/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import RealmSwift

protocol CustomTableViewCellDelegate:NSObjectProtocol {
    func contributionEditNicknameButtonTapped(at indexPathRow: Int)
}

class CustomTableViewCell: UITableViewCell {
    
    //profileCell
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileTitleLabel: UILabel!
    @IBOutlet weak var profileDetailLabel: UILabel!
    
    //themeCell
    @IBOutlet weak var themeImageView: UIImageView!
    @IBOutlet weak var themeTitleLabel: UILabel!
    
    //detailCell
    @IBOutlet weak var detailTitleLabel: UILabel!
    @IBOutlet weak var detailSubTitleLabel: UILabel!
    
    //modifiableCell
    @IBOutlet weak var modifiableTitleLabel: UILabel!
    @IBOutlet weak var modifiableTextField: UITextField!
    
    //contributionCell
    @IBOutlet weak var contributionUserNameTextLabel: UILabel!
    @IBOutlet weak var contributionNicknameTextLabel: UILabel!
    @IBOutlet weak var contributionsWebView: UIWebView!
    @IBOutlet weak var contributionsActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var contributionEditNicknameButtonOutlet: UIButton!
    var indexPath: (section: Int, row: Int) = (section: 0, row: 0)
    var isLargeChart: Bool = false
    
    //donationCell
    @IBOutlet weak var donationImageView: UIImageView!
    @IBOutlet weak var donationTitleLabel: UILabel!
    @IBOutlet weak var donationPriceLabel: UILabel!
    
    var realm: Realm!
    var colleagueObjects:Results<Colleague>!
    var delegate:CustomTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.reuseIdentifier == "contributionsCell" {
            self.contributionsWebView.delegate = self
            self.contributionsWebView.isHidden = true
            self.contributionsWebView.scrollView.delegate = self
            self.contributionsWebView.scrollView.bounces = false
            self.contributionsWebView.backgroundColor = .white
            
            self.contributionsWebView.scrollView.showsVerticalScrollIndicator = false
        }else if self.reuseIdentifier == "themeCell" {
            
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    @IBAction func contributionEditNicknameButtonAction(_ sender: UIButton) {
        self.delegate?.contributionEditNicknameButtonTapped(at: self.indexPath.row)
    }
    
    
}

extension CustomTableViewCell: UIWebViewDelegate, UIScrollViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let xPosition = webView.scrollView.contentSize.width - self.frame.width - 8 + 12
        self.contributionsActivityIndicator.startAnimating()
        webView.stringByEvaluatingJavaScript(from: "document.getElementsByTagName('body')[0].style.fontFamily =\"-apple-system\"")
        webView.stringByEvaluatingJavaScript(from: "document.getElementsByTagName('body')[0].style.fontSize = '10px'")
        
        guard let outerHTML = webView.stringByEvaluatingJavaScript(from: "document.documentElement.outerHTML") else { return }
        
        self.isLargeChart = outerHTML.contains("details-menu")
        print(isLargeChart)
        let isFirstCell = self.indexPath.section == 0 && self.indexPath.row == 0
        let offsetY: CGFloat = isFirstCell ? 60 : isLargeChart ? 70.0 : 35.0
        webView.scrollView.contentOffset = CGPoint(x: xPosition, y: offsetY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.contributionsWebView.isHidden = false
            self.contributionsActivityIndicator.stopAnimating()
        })
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isFirstCell = self.indexPath.section == 0 && self.indexPath.row == 0
        let offsetY: CGFloat = isFirstCell ? 60.0 : isLargeChart ? 70.0 : 35.0

        if scrollView.contentOffset.y != offsetY {
            scrollView.contentOffset.y = offsetY
        }
    }
}

