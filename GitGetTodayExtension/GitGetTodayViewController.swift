//
//  TodayViewController.swift
//  GitGetTodayExtension
//
//  Created by Bo-Young PARK on 14/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    var contributionCollectionView: UICollectionView!
    let sectionInsets = UIEdgeInsets(top: 20, left: 13, bottom: 10, right: 3)
    let itemsPerRow:CGFloat = 7
    let leftSpace:CGFloat = 13
    let rightSpace:CGFloat = 3
    let numberOfWeeks:CGFloat = 26
    let numberOfDaysPerWeek:CGFloat = 7
    let minimumSpaceBetweenItems:CGFloat = 3
    let paddingSpace:CGFloat = 10
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = self.sectionInsets
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        
        let availableWidth = (view.frame.width - self.leftSpace - self.rightSpace - ((self.numberOfWeeks-1) * self.minimumSpaceBetweenItems))
        let widthPerItem = availableWidth/self.numberOfWeeks
        layout.itemSize = CGSize(width: widthPerItem, height: widthPerItem)
        
        self.contributionCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.contributionCollectionView.dataSource = self
        self.contributionCollectionView.delegate = self
        self.contributionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "contributions")
        self.contributionCollectionView.backgroundColor = .clear
        view.addSubview(self.contributionCollectionView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let frame = view.frame
        self.contributionCollectionView.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let availableWidth = (view.frame.width - self.leftSpace - self.rightSpace - ((self.numberOfWeeks-1) * self.minimumSpaceBetweenItems))
        let widthPerItem = availableWidth/self.numberOfWeeks
        let expendedContentHeight:CGFloat = self.sectionInsets.top + self.sectionInsets.bottom + (widthPerItem * self.numberOfDaysPerWeek) + (minimumSpaceBetweenItems * (self.numberOfDaysPerWeek - 1)) + self.paddingSpace
        
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: 0, height: 110)
        }else{
            self.preferredContentSize = CGSize(width: 0, height: expendedContentHeight)
        }
    }
    
}

extension TodayViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 182
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        
        cell.layer.cornerRadius = 1
        cell.backgroundColor = .blue
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
////        let leftSpace:CGFloat = 13
////        let rightSpace:CGFloat = 3
////        let numberOfWeeks:CGFloat = 26
////        let minimumSpaceBetweenItems:CGFloat = 3
////
////        let availableWidth = (view.frame.width - leftSpace - rightSpace - ((numberOfWeeks-1) * minimumSpaceBetweenItems))
////        let widthPerItem = availableWidth/numberOfWeeks
////
////        return CGSize(width: widthPerItem, height: widthPerItem)
//        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
//        let availableWidth = view.frame.width - paddingSpace
//        let widthPerItem = availableWidth / itemsPerRow
//
//        return CGSize(width: widthPerItem, height: widthPerItem)
//    }
}
