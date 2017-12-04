//
//  OpenTodayViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 30/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit


class OpenTodayViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    
    @IBOutlet weak var tutorialImageView: UIImageView!
    @IBOutlet weak var tutorialImageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tutorialImageViewTrailingConstraint: NSLayoutConstraint!
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenSize:CGFloat = self.view.frame.height
        self.selectTutorialImageForIPhoneHeight(of: screenSize)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    @IBAction func skipTutorialButtonAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //iPhone 기종의 높이에 따라 보여지는 이미지를 다르게 함
    func selectTutorialImageForIPhoneHeight(of height:CGFloat) {
        switch height {
        case 812.0: //iPhone X
            self.tutorialImageView.image = UIImage(named: "TutorialOne_en_iPhoneX".localized)
            self.tutorialImageViewBottomConstraint.constant = 0
            self.tutorialImageViewTrailingConstraint.constant = 0
        case 568.0: //iPhone SE
            self.tutorialImageView.image = UIImage(named: "TutorialOne_en_iPhoneSE".localized)
        default:
            self.tutorialImageView.image = UIImage(named: "TutorialOne_en_iPhone".localized)
        }
    }
}


