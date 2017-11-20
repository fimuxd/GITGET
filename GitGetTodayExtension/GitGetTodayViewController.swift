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
    //UILabel_.expanded
    @IBOutlet weak var expandedMondayLabel: UILabel!
    @IBOutlet weak var expandedWednesdayLabel: UILabel!
    @IBOutlet weak var expandedFridayLabel: UILabel!

    //UILabel_.compact
    @IBOutlet weak var compactUserStatusLabel: UILabel!
    
    //CollectionView Attributes
    var contributionCollectionView: UICollectionView!
    let sectionInsets = UIEdgeInsets(top: 3, left: 3, bottom: 6, right: 3)
    let itemsPerRow:CGFloat = 7
    let leftSpace:CGFloat = 20
    let rightSpace:CGFloat = 3
    let numberOfWeeks:CGFloat = 26
    let numberOfDaysPerWeek:CGFloat = 7
    let minimumSpaceBetweenItems:CGFloat = 3
    let paddingSpace:CGFloat = 8
    
    //MonthTextLabel Attributes
    var firstPreviousMonthLabel: UILabel!
    var secondPreviousMonthLabel: UILabel!
    var thirdPreviousMonthLabel: UILabel!
    var fourthPreviousMonthLabel: UILabel!
    var fifthPreviousMonthLabel: UILabel!
    var xPositionForMonthLabels:[CGFloat] = []
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        UserDefaults.standard.set(true, forKey: "isExpanded")
        
        //CollectionView
        let collectionViewLayout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = self.sectionInsets
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumLineSpacing = 2
        collectionViewLayout.minimumInteritemSpacing = 2
        
        let availableWidth = (self.view.frame.width - self.leftSpace - self.rightSpace - ((self.numberOfWeeks-1) * self.minimumSpaceBetweenItems))
        let widthPerItem = availableWidth/self.numberOfWeeks
        collectionViewLayout.itemSize = CGSize(width: widthPerItem, height: widthPerItem)
        
        self.contributionCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        self.contributionCollectionView.dataSource = self
        self.contributionCollectionView.delegate = self
        self.contributionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "contributions")
        self.contributionCollectionView.backgroundColor = .clear
        self.view.addSubview(self.contributionCollectionView)
        
        //MonthLabels
        self.firstPreviousMonthLabel = UILabel(frame: .zero)
        self.secondPreviousMonthLabel = UILabel(frame: .zero)
        self.thirdPreviousMonthLabel = UILabel(frame: .zero)
        self.fourthPreviousMonthLabel = UILabel(frame: .zero)
        self.fifthPreviousMonthLabel = UILabel(frame: .zero)
        
        self.firstPreviousMonthLabel.textColor = UIColor(hex: "767676")
        self.secondPreviousMonthLabel.textColor = UIColor(hex: "767676")
        self.thirdPreviousMonthLabel.textColor = UIColor(hex: "767676")
        self.fourthPreviousMonthLabel.textColor = UIColor(hex: "767676")
        self.fifthPreviousMonthLabel.textColor = UIColor(hex: "767676")
        
        self.firstPreviousMonthLabel.font = UIFont(name: self.firstPreviousMonthLabel.font.fontName, size: 13)
        self.secondPreviousMonthLabel.font = UIFont(name: self.secondPreviousMonthLabel.font.fontName, size: 13)
        self.thirdPreviousMonthLabel.font = UIFont(name: self.thirdPreviousMonthLabel.font.fontName, size: 13)
        self.fourthPreviousMonthLabel.font = UIFont(name: self.fourthPreviousMonthLabel.font.fontName, size: 13)
        self.fifthPreviousMonthLabel.font = UIFont(name: self.fifthPreviousMonthLabel.font.fontName, size: 13)
        
        self.view.addSubview(self.firstPreviousMonthLabel)
        self.view.addSubview(self.secondPreviousMonthLabel)
        self.view.addSubview(self.thirdPreviousMonthLabel)
        self.view.addSubview(self.fourthPreviousMonthLabel)
        self.view.addSubview(self.fifthPreviousMonthLabel)
        self.getMonthTextForLabel()
//        self.setCompactMode()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if UserDefaults.standard.bool(forKey: "isExpanded") == true {
            let superViewFrame = self.view.frame
            let collectionViewFrame = CGRect(x: superViewFrame.origin.x + 20, y: superViewFrame.origin.y + 20, width: superViewFrame.size.width - 20, height: superViewFrame.size.height - 20)
            
            if self.xPositionForMonthLabels.count == 5 {
                self.xPositionForMonthLabels.sorted()
                self.firstPreviousMonthLabel.frame = CGRect(x: self.xPositionForMonthLabels[4], y: 3, width: 24, height: 16)
                self.secondPreviousMonthLabel.frame = CGRect(x: self.xPositionForMonthLabels[3], y: 3, width: 24, height: 16)
                self.thirdPreviousMonthLabel.frame = CGRect(x: self.xPositionForMonthLabels[2], y: 3, width: 24, height: 16)
                self.fourthPreviousMonthLabel.frame = CGRect(x: self.xPositionForMonthLabels[1], y: 3, width: 24, height: 16)
                if self.xPositionForMonthLabels[0] > 10 {
                    self.fifthPreviousMonthLabel.frame = CGRect(x: self.xPositionForMonthLabels[0], y: 3, width: 24, height: 16)
                }else{
                    self.fifthPreviousMonthLabel.frame = CGRect(x: -50, y: 3, width: 24, height: 16)
                }
            }
            self.contributionCollectionView.frame = collectionViewFrame
            
            if self.firstPreviousMonthLabel.isHidden == true {
            self.setExpandedMode()
            }
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    //Widget을 터치하면 GitGet App 이 열리도록 설정
    @IBAction func toOpenGitGetApp(_ sender: UITapGestureRecognizer) {
        openApp(sender)
    }
    
    func openApp(_ sender:AnyObject) {
        let myAppUrl = URL(string: "main-screen://")!
        extensionContext?.open(myAppUrl, completionHandler: { (success) in
            if (!success) {
                print("///ERROR: failed to open app from Today Extension")
            }
        })
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            //MARK:- .compact는 default 값으로, 높이 값이 정해져 있어 조절이 불가능 하다. (fixed 110px)
            self.setCompactMode()
            self.preferredContentSize = maxSize //110px
            UserDefaults.standard.set(false, forKey: "isExpanded")
        }else{
            self.setExpandedMode()
            //.expanded
            let expandedAvailableWidth = (view.frame.width - self.leftSpace - self.rightSpace - ((self.numberOfWeeks-1) * self.minimumSpaceBetweenItems))
            let expandedWidthPerItem = expandedAvailableWidth/self.numberOfWeeks
            let expandedContentHeight:CGFloat = self.sectionInsets.top + self.sectionInsets.bottom + 20 + (expandedWidthPerItem * self.numberOfDaysPerWeek) + (minimumSpaceBetweenItems * (self.numberOfDaysPerWeek - 1)) + self.paddingSpace
            self.preferredContentSize = CGSize(width: 0, height: expandedContentHeight)
            UserDefaults.standard.set(true, forKey: "isExpanded")
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
    
    //TODO:- 이거 완전 미친 하드코딩임. enum을 쓰던 어떻게 해서 개선할 것
    func getMonthTextForLabel() {
        let date:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        guard let timeZone:TimeZone = TimeZone(abbreviation: "UTC"),
            let utcMonth = dateFormatter.calendar.dateComponents(in: timeZone, from: date).month else {return}
        
        switch utcMonth {
        case 1:
            self.firstPreviousMonthLabel.text = "Dec"
            self.secondPreviousMonthLabel.text = "Nov"
            self.thirdPreviousMonthLabel.text = "Oct"
            self.fourthPreviousMonthLabel.text = "Sep"
            self.fifthPreviousMonthLabel.text = "Aug"
        case 2:
            self.firstPreviousMonthLabel.text = "Jan"
            self.secondPreviousMonthLabel.text = "Dec"
            self.thirdPreviousMonthLabel.text = "Nov"
            self.fourthPreviousMonthLabel.text = "Oct"
            self.fifthPreviousMonthLabel.text = "Sep"
        case 3:
            self.firstPreviousMonthLabel.text = "Feb"
            self.secondPreviousMonthLabel.text = "Jan"
            self.thirdPreviousMonthLabel.text = "Dec"
            self.fourthPreviousMonthLabel.text = "Nov"
            self.fifthPreviousMonthLabel.text = "Oct"
        case 4:
            self.firstPreviousMonthLabel.text = "Mar"
            self.secondPreviousMonthLabel.text = "Feb"
            self.thirdPreviousMonthLabel.text = "Jan"
            self.fourthPreviousMonthLabel.text = "Dec"
            self.fifthPreviousMonthLabel.text = "Nov"
        case 5:
            self.firstPreviousMonthLabel.text = "Apr"
            self.secondPreviousMonthLabel.text = "Mar"
            self.thirdPreviousMonthLabel.text = "Feb"
            self.fourthPreviousMonthLabel.text = "Jan"
            self.fifthPreviousMonthLabel.text = "Dec"
        case 6:
            self.firstPreviousMonthLabel.text = "May"
            self.secondPreviousMonthLabel.text = "Apr"
            self.thirdPreviousMonthLabel.text = "Mar"
            self.fourthPreviousMonthLabel.text = "Feb"
            self.fifthPreviousMonthLabel.text = "Jan"
        case 7:
            self.firstPreviousMonthLabel.text = "Jun"
            self.secondPreviousMonthLabel.text = "May"
            self.thirdPreviousMonthLabel.text = "Apr"
            self.fourthPreviousMonthLabel.text = "Mar"
            self.fifthPreviousMonthLabel.text = "Feb"
        case 8:
            self.firstPreviousMonthLabel.text = "Jul"
            self.secondPreviousMonthLabel.text = "Jun"
            self.thirdPreviousMonthLabel.text = "May"
            self.fourthPreviousMonthLabel.text = "Apr"
            self.fifthPreviousMonthLabel.text = "Mar"
        case 9:
            self.firstPreviousMonthLabel.text = "Aug"
            self.secondPreviousMonthLabel.text = "Jul"
            self.thirdPreviousMonthLabel.text = "Jun"
            self.fourthPreviousMonthLabel.text = "May"
            self.fifthPreviousMonthLabel.text = "Apr"
        case 10:
            self.firstPreviousMonthLabel.text = "Sep"
            self.secondPreviousMonthLabel.text = "Aug"
            self.thirdPreviousMonthLabel.text = "Jul"
            self.fourthPreviousMonthLabel.text = "Jun"
            self.fifthPreviousMonthLabel.text = "May"
        case 11:
            self.firstPreviousMonthLabel.text = "Oct"
            self.secondPreviousMonthLabel.text = "Sep"
            self.thirdPreviousMonthLabel.text = "Aug"
            self.fourthPreviousMonthLabel.text = "Jul"
            self.fifthPreviousMonthLabel.text = "Jun"
        case 12:
            self.firstPreviousMonthLabel.text = "Nov"
            self.secondPreviousMonthLabel.text = "Oct"
            self.thirdPreviousMonthLabel.text = "Sep"
            self.fourthPreviousMonthLabel.text = "Aug"
            self.fifthPreviousMonthLabel.text = "Jul"
        default: break
        }
    }
    
    func findIndexPathForFirstOfPreviousMonth(numberOf:Int) -> Int {
        let date:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        guard let timeZone:TimeZone = TimeZone(abbreviation: "UTC"),
            let utcYear = dateFormatter.calendar.dateComponents(in: timeZone, from: date).year,
            let utcMonth = dateFormatter.calendar.dateComponents(in: timeZone, from: date).month else {return 0}
        
        var utcMonthString:String = ""
        if utcMonth - numberOf == 1 {
            utcMonthString = "12"
        }else if utcMonth - numberOf < 10 {
            utcMonthString = "0\(utcMonth-numberOf)"
        }else{
            utcMonthString = "\(utcMonth-numberOf)"
        }
        let previousDateString:String = "\(utcYear)-\(utcMonthString)-01"
        
        let userDefaults = UserDefaults(suiteName: "group.fimuxd.TodayExtensionSharingDefaults")
        userDefaults?.synchronize()
        
        guard let realDateArray:[String] = userDefaults?.array(forKey: "ContributionsDates") as? [String],
            let indexPath = realDateArray.index(of: previousDateString) else {return 0}
        return indexPath
    }
    
    func setCompactMode() {
        self.contributionCollectionView.isHidden = true
        self.expandedMondayLabel.isHidden = true
        self.expandedWednesdayLabel.isHidden = true
        self.expandedFridayLabel.isHidden = true
        self.firstPreviousMonthLabel.isHidden = true
        self.secondPreviousMonthLabel.isHidden = true
        self.thirdPreviousMonthLabel.isHidden = true
        self.fourthPreviousMonthLabel.isHidden = true
        self.fifthPreviousMonthLabel.isHidden = true
        self.compactUserStatusLabel.isHidden = false
    }
    
    func setExpandedMode() {
        
        self.expandedMondayLabel.isHidden = false
        self.expandedWednesdayLabel.isHidden = false
        self.expandedFridayLabel.isHidden = false
        self.firstPreviousMonthLabel.isHidden = false
        self.secondPreviousMonthLabel.isHidden = false
        self.thirdPreviousMonthLabel.isHidden = false
        self.fourthPreviousMonthLabel.isHidden = false
        self.fifthPreviousMonthLabel.isHidden = false
        self.compactUserStatusLabel.isHidden = true
        self.contributionCollectionView.isHidden = false
    }
    
    //Widget이 LayoutSubview 될 때마다 Noti: 날려서 새로운 commit 이 있는지 확인할 것
//    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
//      completionHandler(.newData)
//    }
    
    func updateGithubData() {
        
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
        
        let userDefaults = UserDefaults(suiteName: "group.fimuxd.TodayExtensionSharingDefaults")
        userDefaults?.synchronize()
        
        
        if let realHexColorCodes:[String] = userDefaults?.array(forKey: "ContributionsDatas") as? [String] {
            
            cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 189])
            
            for index in 1...5 {
                if (indexPath.row + 189) == self.findIndexPathForFirstOfPreviousMonth(numberOf: index) {
                    let xPosition:CGFloat = cell.frame.origin.x
                    self.xPositionForMonthLabels.append(xPosition + 23)
                    print("여기:\(xPositionForMonthLabels) ")
                }
            }
        }
        
        return cell
    }
    
    
}

extension UIColor {
    convenience init(hex: String) {
        var hexNumber:String = hex
        
        if hex.contains("#") {
            hexNumber.remove(at: hexNumber.index(of: "#")!)
        }
        
        let scanner = Scanner(string: hexNumber)
        scanner.scanLocation = 0
        
        var rgbValue:UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let red = (rgbValue & 0xff0000) >> 16
        let green = (rgbValue & 0xff00) >> 8
        let blue = rgbValue & 0xff
        
        self.init(red:CGFloat(red)/0xff, green:CGFloat(green)/0xff, blue:CGFloat(blue)/0xff, alpha:0.9)
    }
}

