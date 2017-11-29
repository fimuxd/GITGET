//
//  TodayViewController.swift
//  GitGetTodayExtension
//
//  Created by Bo-Young PARK on 14/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import NotificationCenter

import Alamofire
import SwiftyJSON
import SwiftSoup

class TodayViewController: UIViewController, NCWidgetProviding {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    //UILabel_.expanded
    @IBOutlet weak var mondayLabel: UILabel!
    @IBOutlet weak var wednesdayLabel: UILabel!
    @IBOutlet weak var fridayLabel: UILabel!
    
    //UILabel_.expanded
    @IBOutlet weak var expandedUserStatusLabel: UILabel!
    
    //MonthTextLabel
    @IBOutlet weak var currentMonthLabel: UILabel!
    @IBOutlet weak var firstPreviousMonthLabel: UILabel!
    @IBOutlet weak var secondPreviousMonthLabel: UILabel!
    @IBOutlet weak var thirdPreviousMonthLabel: UILabel!
    @IBOutlet weak var fourthPreviousMonthLabel: UILabel!
    @IBOutlet weak var fifthPreviousMonthLabel: UILabel!
    @IBOutlet weak var sixthPreviousMonthLabel: UILabel!
    
    //MonthTextLabelAttribute
    @IBOutlet weak var currentMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var thirdMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fourthMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fifthMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sixthMonthLabelLeadingConstraint: NSLayoutConstraint!
    
    //UILabel_.상태확인바
    @IBOutlet weak var widgetStatusLabel: UILabel!
    
    //collectionView
    @IBOutlet weak var contributionCollectionView: UICollectionView!
    
    //indicator
    @IBOutlet weak var dataActivityIndicator: UIActivityIndicatorView!
    
    var xPositionForMonthLabels:[CGFloat] = []
    var isSignedIn:Bool = false
    
    //Contributions 관련 Data 통신 Array
    
    var oldHexColorCodesArray = UserDefaults.standard.value(forKey: "HexColorCodes") as? [String]
    var hexColorCodesArray:[String]? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDatas") as? [String] {
        willSet(oldArray){
            UserDefaults.standard.set(oldArray, forKey: "HexColorCodes")
            self.dataActivityIndicator.stopAnimating()
        }
        didSet(newArray){
            guard let realHexColorCodes = hexColorCodesArray,
                let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            
//            userDefaults.setValue(realHexColorCodes, forKey: "ContributionsDatas")
//            userDefaults.synchronize()
            
            guard let realOldArray:[String] = oldHexColorCodesArray else {return}
            if realOldArray != realHexColorCodes {
                print("색상 업데이트 됨: 예전\(self.oldHexColorCodesArray?.count), 새것\(realHexColorCodes.count)")
                userDefaults.setValue(realOldArray, forKey: "ContributionsDatas")
                userDefaults.synchronize()
                self.contributionCollectionView.reloadData()
            }else{
                print("색상 새로고침 할 것 없음: 예전\(self.oldHexColorCodesArray?.count), 새것\(realHexColorCodes.count)")
            }
            self.dataActivityIndicator.stopAnimating()
        }
    }
    
    var oldDateArray = UserDefaults.standard.value(forKey: "Dates") as? [String]
    var dateArray:[String]? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDates") as? [String] {
        willSet(oldArray){
            UserDefaults.standard.set(oldArray, forKey: "Dates")
            self.dataActivityIndicator.stopAnimating()
        }
        didSet(newArray){
            guard let realDateArray = dateArray,
                let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            
//            userDefaults.setValue(realDateArray, forKey: "ContributionsDates")
//            userDefaults.synchronize()
            
            guard let realOldArray:[String] = oldDateArray else {return}
            if realOldArray != realDateArray {
                print("날짜 업데이트 됨: 예전\(self.oldDateArray?.count), 새것\(realDateArray.count)")
                userDefaults.setValue(realDateArray, forKey: "ContributionsDates")
                userDefaults.synchronize()
                self.contributionCollectionView.reloadData()
            }else{
                print("날짜 새로고침 할 것 없음: 예전\(self.oldDateArray?.count), 새것\(realDateArray.count)")
            }
            self.dataActivityIndicator.stopAnimating()
        }
    }
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("//TE_awakeFromNib")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("//TE_viewDidLoad")
        extensionContext?.widgetLargestAvailableDisplayMode = .compact
        
        guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
        userDefaults.synchronize()
        
        self.isSignedIn = userDefaults.bool(forKey: "isSigned")
        
        if self.isSignedIn == true {
            self.contributionCollectionView.backgroundColor = .clear
            self.getMonthTextForLabel()
        }else{
            self.widgetStatusLabel.text = "Open GITGET to get your contributions :)\n\n  • Double tap to open \n  • Single tap to refresh"
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("//TE_viewWillLayoutSubviews")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("//TE_viewDidLayoutSubviews")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("//TE_viewWillAppear")
        
        guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
        userDefaults.synchronize()
        
        self.isSignedIn = userDefaults.bool(forKey: "isSigned")
        
        if self.isSignedIn == true {
            let screenWidth:CGFloat = self.view.frame.width
            switch screenWidth {
            case 398.0: //iPhone Plus
                if self.xPositionForMonthLabels[5] < 351 {
                    self.currentMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[6]
                }else{
                    self.currentMonthLabel.isHidden = true
                }
                self.firstMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[5]
                self.secondMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[4]
                self.thirdMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[3]
                self.fourthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[2]
                self.fifthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[1]
                if self.xPositionForMonthLabels[0] > 12 {
                    self.sixthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[0]
                }else{
                    self.sixthPreviousMonthLabel.isHidden = true
                }
            case 359.0: //iPhone 6,7,8,X
                if self.xPositionForMonthLabels[5] < 311 {
                    self.currentMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[5]
                }else{
                    self.currentMonthLabel.isHidden = true
                }
                self.firstMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[4]
                self.secondMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[3]
                self.thirdMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[2]
                self.fourthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[1]
                if self.xPositionForMonthLabels[0] > 12 {
                    self.fifthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[0]
                }else{
                    self.fifthPreviousMonthLabel.isHidden = true
                }
                self.sixthPreviousMonthLabel.isHidden = true
            case 304.0: //iPhone 4,5,SE
                
                if self.xPositionForMonthLabels[4] < 251 {
                    self.currentMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[4]
                }else{
                    self.currentMonthLabel.isHidden = true
                }
                self.firstMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[3]
                self.secondMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[2]
                self.thirdMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[1]
                if self.xPositionForMonthLabels[0] > 12 {
                    self.fourthMonthLabelLeadingConstraint.constant = self.xPositionForMonthLabels[0]
                }else{
                    self.fourthPreviousMonthLabel.isHidden = true
                }
                self.fifthPreviousMonthLabel.isHidden = true
                self.sixthPreviousMonthLabel.isHidden = true
            default:
                self.expandedUserStatusLabel.text = "Unable into Load"
            }
//            self.contributionCollectionView.reloadData()
            
            
        }else{
            self.widgetStatusLabel.text = "Open GITGET to get your contributions :)\n\n  • Double tap to open \n  • Single tap to refresh"
            self.contributionCollectionView.isHidden = true
            self.mondayLabel.isHidden = true
            self.wednesdayLabel.isHidden = true
            self.fridayLabel.isHidden = true
            self.currentMonthLabel.isHidden = true
            self.firstPreviousMonthLabel.isHidden = true
            self.secondPreviousMonthLabel.isHidden = true
            self.thirdPreviousMonthLabel.isHidden = true
            self.fourthPreviousMonthLabel.isHidden = true
            self.fifthPreviousMonthLabel.isHidden = true
            self.sixthPreviousMonthLabel.isHidden = true
        }
        self.dataActivityIndicator.stopAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("//TE_viewDidApear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("//TE_viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("//TE_viewDidDisappear")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        print("//TE_deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    //Widget을 두번 탭하면 GitGet App 이 열리도록 설정
    @IBAction func toOpenGitGetApp(_ sender: UITapGestureRecognizer) {
        openApp(sender)
    }
    
    //Widget을 한번 탭하면 GitGet이 새로고침 됨
    @IBAction func toRefershGitGetApp(_ sender: UITapGestureRecognizer) {
        self.dataActivityIndicator.startAnimating()
        guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults"),
            let realGitHubID:String = userDefaults.value(forKey: "GitHubID") as? String else {return}
        userDefaults.synchronize()
        self.updateContributionDatasOf(gitHubID: realGitHubID)
    }
    
    
    func openApp(_ sender:AnyObject) {
        let myAppUrl = URL(string: "main-screen://")!
        extensionContext?.open(myAppUrl, completionHandler: { (success) in
            if (!success) {
                print("///ERROR: failed to open app from Today Extension")
            }
        })
    }
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")
        guard let contributionDatas:[String] = userDefaults?.object(forKey: "ContributionsDatas") as? [String],
            let contributionDates:[String] = userDefaults?.object(forKey: "ContributionsDates") as? [String],
            let todayContribution:String = userDefaults?.object(forKey: "TodayContributions") as? String else {return}
        
        //        self.expandedUserStatusLabel.text! = "Cheer up! \(todayContribution) contributions today!"
        
        print("//TE_widgetPerformUpdate:\(NCUpdateResult.newData)")
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize //.compact는 default 값으로, 높이 값이 정해져 있어 조절이 불가능 하다. (fixed 110px)
            self.expandedUserStatusLabel.isHidden = true
        }else{
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults"),
                let todayContributions:String = userDefaults.object(forKey: "TodayContributions") as? String else {return}
            userDefaults.synchronize()
            self.expandedUserStatusLabel.text! = "Cheer up! \(todayContributions) contributions today!"
            self.expandedUserStatusLabel.isHidden = false
            
            self.preferredContentSize = CGSize(width: 0, height: 220)
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
        print("현재는 \(utcWeekDay)번째 요일입니다.")
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
            self.currentMonthLabel.text = "Jan"
            self.firstPreviousMonthLabel.text = "Dec"
            self.secondPreviousMonthLabel.text = "Nov"
            self.thirdPreviousMonthLabel.text = "Oct"
            self.fourthPreviousMonthLabel.text = "Sep"
            self.fifthPreviousMonthLabel.text = "Aug"
            self.sixthPreviousMonthLabel.text = "Jul"
        case 2:
            self.currentMonthLabel.text = "Feb"
            self.firstPreviousMonthLabel.text = "Jan"
            self.secondPreviousMonthLabel.text = "Dec"
            self.thirdPreviousMonthLabel.text = "Nov"
            self.fourthPreviousMonthLabel.text = "Oct"
            self.fifthPreviousMonthLabel.text = "Sep"
            self.sixthPreviousMonthLabel.text = "Aug"
        case 3:
            self.currentMonthLabel.text = "Mar"
            self.firstPreviousMonthLabel.text = "Feb"
            self.secondPreviousMonthLabel.text = "Jan"
            self.thirdPreviousMonthLabel.text = "Dec"
            self.fourthPreviousMonthLabel.text = "Nov"
            self.fifthPreviousMonthLabel.text = "Oct"
            self.sixthPreviousMonthLabel.text = "Sep"
        case 4:
            self.currentMonthLabel.text = "Apr"
            self.firstPreviousMonthLabel.text = "Mar"
            self.secondPreviousMonthLabel.text = "Feb"
            self.thirdPreviousMonthLabel.text = "Jan"
            self.fourthPreviousMonthLabel.text = "Dec"
            self.fifthPreviousMonthLabel.text = "Nov"
            self.sixthPreviousMonthLabel.text = "Oct"
        case 5:
            self.currentMonthLabel.text = "May"
            self.firstPreviousMonthLabel.text = "Apr"
            self.secondPreviousMonthLabel.text = "Mar"
            self.thirdPreviousMonthLabel.text = "Feb"
            self.fourthPreviousMonthLabel.text = "Jan"
            self.fifthPreviousMonthLabel.text = "Dec"
            self.sixthPreviousMonthLabel.text = "Nov"
        case 6:
            self.currentMonthLabel.text = "Jun"
            self.firstPreviousMonthLabel.text = "May"
            self.secondPreviousMonthLabel.text = "Apr"
            self.thirdPreviousMonthLabel.text = "Mar"
            self.fourthPreviousMonthLabel.text = "Feb"
            self.fifthPreviousMonthLabel.text = "Jan"
            self.sixthPreviousMonthLabel.text = "Dec"
        case 7:
            self.currentMonthLabel.text = "Jul"
            self.firstPreviousMonthLabel.text = "Jun"
            self.secondPreviousMonthLabel.text = "May"
            self.thirdPreviousMonthLabel.text = "Apr"
            self.fourthPreviousMonthLabel.text = "Mar"
            self.fifthPreviousMonthLabel.text = "Feb"
            self.sixthPreviousMonthLabel.text = "Jan"
        case 8:
            self.currentMonthLabel.text = "Aug"
            self.firstPreviousMonthLabel.text = "Jul"
            self.secondPreviousMonthLabel.text = "Jun"
            self.thirdPreviousMonthLabel.text = "May"
            self.fourthPreviousMonthLabel.text = "Apr"
            self.fifthPreviousMonthLabel.text = "Mar"
            self.sixthPreviousMonthLabel.text = "Feb"
        case 9:
            self.currentMonthLabel.text = "Sep"
            self.firstPreviousMonthLabel.text = "Aug"
            self.secondPreviousMonthLabel.text = "Jul"
            self.thirdPreviousMonthLabel.text = "Jun"
            self.fourthPreviousMonthLabel.text = "May"
            self.fifthPreviousMonthLabel.text = "Apr"
            self.sixthPreviousMonthLabel.text = "Mar"
        case 10:
            self.currentMonthLabel.text = "Oct"
            self.firstPreviousMonthLabel.text = "Sep"
            self.secondPreviousMonthLabel.text = "Aug"
            self.thirdPreviousMonthLabel.text = "Jul"
            self.fourthPreviousMonthLabel.text = "Jun"
            self.fifthPreviousMonthLabel.text = "May"
            self.sixthPreviousMonthLabel.text = "Apr"
        case 11:
            self.currentMonthLabel.text = "Nov"
            self.firstPreviousMonthLabel.text = "Oct"
            self.secondPreviousMonthLabel.text = "Sep"
            self.thirdPreviousMonthLabel.text = "Aug"
            self.fourthPreviousMonthLabel.text = "Jul"
            self.fifthPreviousMonthLabel.text = "Jun"
            self.sixthPreviousMonthLabel.text = "Mar"
        case 12:
            self.currentMonthLabel.text = "Dec"
            self.firstPreviousMonthLabel.text = "Nov"
            self.secondPreviousMonthLabel.text = "Oct"
            self.thirdPreviousMonthLabel.text = "Sep"
            self.fourthPreviousMonthLabel.text = "Aug"
            self.fifthPreviousMonthLabel.text = "Jul"
            self.sixthPreviousMonthLabel.text = "Jun"
        default: break
        }
    }
    
    func findIndexPathForFirstOf(previousMonthNumber:Int) -> Int {
        let date:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        guard let timeZone:TimeZone = TimeZone(abbreviation: "UTC"),
            let utcYear = dateFormatter.calendar.dateComponents(in: timeZone, from: date).year,
            let utcMonth = dateFormatter.calendar.dateComponents(in: timeZone, from: date).month else {return 0}
        var utcMonthString:String = ""
        
        if utcMonth - previousMonthNumber == 1 {
            utcMonthString = "12"
        }else if utcMonth - previousMonthNumber < 10 {
            utcMonthString = "0\(utcMonth - previousMonthNumber)"
        }else{
            utcMonthString = "\(utcMonth - previousMonthNumber)"
        }
        
        let previousDateString:String = "\(utcYear)-\(utcMonthString)-01"
        
        let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")
        userDefaults?.synchronize()
        
        guard let realDateArray:[String] = userDefaults?.array(forKey: "ContributionsDates") as? [String],
            let indexPath = realDateArray.index(of: previousDateString) else {return 0}
        return indexPath
    }
    
    //MARK:- 데이터 업데이트
    func updateContributionDatasOf(gitHubID:String) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {return}
        Alamofire.request(getContributionsUrl, method: .get).responseString { [unowned self] (response) in
            switch response.result {
            case .success(let value):
                //https://github.com/users/\(username)/contributions 링크를 통해 가져온 HTML 내용 중, 필요한 정보만 추출하기
                do {
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return} //parse html_rect
                    var tempColorCodeArray:[String] = []
                    var tempDateArray:[String] = []
                    //color code 추출하기
                    for element:Element in elements.array() {
                        guard let hexColorCode:String = try? element.attr("fill") else {return}
                        tempColorCodeArray.append(hexColorCode)
                    }
                    self.hexColorCodesArray = tempColorCodeArray
                    
                    //date(날짜) 추출하기
                    for element:Element in elements.array() {
                        guard let date:String = try? element.attr("data-date") else {return}
                        tempDateArray.append(date)
                    }
                    self.dateArray = tempDateArray
                    print("데이트 통신하나요? \(self.dateArray?.count)")
                }catch Exception.Error(let type, let result){
                    print(result, type)
                }catch{
                    print("error")
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
}


extension TodayViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let screenSize:CGFloat = self.view.frame.width
        switch screenSize {
        case 398.0: //iPhone Plus
            return 224 + getUTCWeekdayFromLocalTime()
        case 359.0: //iPhone, X
            return 203 + getUTCWeekdayFromLocalTime()
        case 304.0: //iPhone SE, 4
            return 168  + getUTCWeekdayFromLocalTime()
        default:
            self.fridayLabel.text = "Unable to Load"
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        
        let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")
        userDefaults?.synchronize()
        
//        if let realHexColorCodes:[String] = userDefaults?.array(forKey: "ContributionsDatas") as? [String] {
        if let realHexColorCodes:[String] = self.hexColorCodesArray {
            let screenSize:CGFloat = self.view.frame.width
            switch screenSize {
            case 398.0: //iPhone Plus
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 140])
                for index in 0...6 {
                    if (indexPath.row + 140) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                    }
                }
            case 359.0: //iPhone, X
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 161])
                for index in 0...5 {
                    if (indexPath.row + 161) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                    }
                }
            case 304.0: //iPhone SE, 4
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 196])
                for index in 0...4 {
                    if (indexPath.row + 196) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                        print(self.xPositionForMonthLabels)
                    }
                }
            default:
                self.fridayLabel.text = "Unable to Load"
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

