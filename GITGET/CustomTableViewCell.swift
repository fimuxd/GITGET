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
    func contributionEditNicknameButtonTapped(at indexPathRow:Int)
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
    var indexPathRow:Int = 0
    
    var realm: Realm!
    var colleagueObjects:Results<Colleague>!
    var delegate:CustomTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.reuseIdentifier == "contributionsCell" {
            self.contributionsWebView.delegate = self
            self.contributionsWebView.isHidden = true
            self.contributionsWebView.scrollView.bounces = false
            self.contributionsWebView.backgroundColor = .white
            
        }else if self.reuseIdentifier == "themeCell" {
            
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    @IBAction func contributionEditNicknameButtonAction(_ sender: UIButton) {
        self.delegate?.contributionEditNicknameButtonTapped(at: self.indexPathRow)
    }
    
    
}

extension CustomTableViewCell:UIWebViewDelegate {
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let xPosition = webView.scrollView.contentSize.width - self.frame.width - 8 + 12
        self.contributionsActivityIndicator.startAnimating()
        webView.stringByEvaluatingJavaScript(from: "document.getElementsByTagName('body')[0].style.fontFamily =\"-apple-system\"")
        webView.stringByEvaluatingJavaScript(from: "document.getElementsByTagName('body')[0].style.fontSize = '10px'")
        webView.scrollView.contentOffset = CGPoint(x: xPosition, y: 0.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.contributionsWebView.isHidden = false
            self.contributionsActivityIndicator.stopAnimating()
        })
    }
}

