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
    let sectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 0)
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
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let availableWidth = (view.frame.width - self.leftSpace - self.rightSpace - ((self.numberOfWeeks-1) * self.minimumSpaceBetweenItems))
        let widthPerItem = availableWidth/self.numberOfWeeks
        let expendedContentHeight:CGFloat = self.sectionInsets.top + self.sectionInsets.bottom + (widthPerItem * self.numberOfDaysPerWeek) + (minimumSpaceBetweenItems * (self.numberOfDaysPerWeek - 1)) + self.paddingSpace
        
        if activeDisplayMode == .compact {
            //TODO:- 일주일치의 Contributions이 나오도록 할 것
            self.preferredContentSize = CGSize(width: 0, height: 110)
        }else{
            self.preferredContentSize = CGSize(width: 0, height: expendedContentHeight)
        }
    }
    
    //현재 Local 시간을 UTC 기준으로 변환하여 요일수로 반환하기
    //GitHub: Contributions are timestamped according to Coordinated Universal Time (UTC) rather than your local time zone.
    //참고: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile/
    func getUTCWeekdayFromLocalTime() -> Int {
        let date:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        guard let timeZone:TimeZone = TimeZone(abbreviation: "UTC"),
            let utcWeekDay = dateFormatter.calendar.dateComponents(in: timeZone, from: date).weekday else {return 0}
        
        return utcWeekDay
    }
}


extension TodayViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch getUTCWeekdayFromLocalTime() {
        case 1: //일(Sunday)
            return 176
        case 2: //월(Monday)
            return 177
        case 3: //화(Tuesday)
            return 178
        case 4: //수(Wednesday)
            return 179
        case 5: //목(Thursday)
            return 180
        case 6: //금(Friday)
            return 181
        case 7: //토(Saturday)
            return 182
        default:
            print("///ERROR: 날짜 계산이 잘못되었습니다.")
            return 182
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        cell.layer.cornerRadius = 1
        cell.backgroundColor = UIColor(hex: "EBEDF0")
        return cell
    }
    
    
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue:UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let red = (rgbValue & 0xff0000) >> 16
        let green = (rgbValue & 0xff00) >> 8
        let blue = rgbValue & 0xff
        
        self.init(red:CGFloat(red)/0xff, green:CGFloat(green)/0xff, blue:CGFloat(blue)/0xff, alpha:1)
    }
}
