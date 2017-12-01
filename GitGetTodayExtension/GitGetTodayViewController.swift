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

//TODO:- monthString 인간적으로 정리좀 하자 진심.
//enum {
//
//}


class TodayViewController: UIViewController, NCWidgetProviding {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    //UILabel_.expanded
    @IBOutlet weak var mondayLabel: UILabel!
    @IBOutlet weak var wednesdayLabel: UILabel!
    @IBOutlet weak var fridayLabel: UILabel!
    
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
    
    //UICollectionView
    @IBOutlet weak var contributionCollectionView: UICollectionView!
    
    //UIActivityIndicator
    @IBOutlet weak var dataActivityIndicator: UIActivityIndicatorView!
    
    //깃젯 앱과 통신하여 가져오는 UserDefaults 값
    let isSignedIn:Bool? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "isSigned") as? Bool
    let currentGitHubID:String? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String
    
    //월별 Label 위치 목록 가져옴
    var xPositionForMonthLabels:[CGFloat] = [] {
        willSet(newValue){
            if xPositionForMonthLabels != newValue {
                self.xPositionForMonthLabels = newValue
                
                let screenSize:CGFloat = self.view.frame.width
                switch screenSize {
                case 398.0: //iPhone Plus
                    if newValue.count == 7 {
                        self.setMonthLabelXPositions(with: newValue)
                    }
                case 359.0: //iPhone, X
                    if newValue.count == 6 {
                        self.setMonthLabelXPositions(with: newValue)
                    }
                case 304.0: //iPhone SE, 4
                    if newValue.count == 5 {
                        self.setMonthLabelXPositions(with: newValue)
                    }
                default:
                    self.widgetStatusLabel.text = "Unable to Load"
                }
            }
        }
    }
    
    //Contributions 관련 Data 통신: 앱 설치 및 로그인 후 최초 1회만 앱을 통해 통신한 값을 띄우고, 이후부터는 위젯이 직접통신하는 구조
    //색상 코드 목록 가져옴
    var oldHexColorCodesArray:[String]? = []
    var hexColorCodesArray = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDatas") as? [String] {
        didSet(oldValue){
            self.oldHexColorCodesArray = oldValue
            self.dataActivityIndicator.stopAnimating()
        }
        willSet(newValue){
            guard let realOldHexColorCodesArray = self.oldHexColorCodesArray,
                let realNewValueArray = newValue else {self.dataActivityIndicator.stopAnimating(); return}
            if realOldHexColorCodesArray != realNewValueArray {
                self.hexColorCodesArray = realNewValueArray
                print("//색상 업데이트 됨: 예전\(realOldHexColorCodesArray.last ?? "값없음"), 새것\(realNewValueArray.last ?? "값없음")")
                self.contributionCollectionView.reloadData()
            }else{
                print("//색상 새로고침 할 것 없음: 예전\(realOldHexColorCodesArray.last ?? "값없음"), 새것\(realNewValueArray.last ?? "값없음")")
                self.dataActivityIndicator.stopAnimating()
            }
        }
    }
    
    //날짜목록 가져옴
    var oldDateArray:[String]? = []
    var dateArray = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDates") as? [String] {
        didSet(oldValue){
            self.oldDateArray = oldValue
        }
        willSet(newValue){
            guard let realOldDateArray = self.oldDateArray,
                let realNewValueArray = newValue else {return}
            if realOldDateArray != realNewValueArray {
                self.dateArray = realNewValueArray
                print("//날짜 업데이트 됨: 예전\(realOldDateArray.last ?? "값없음"), 새것\(realNewValueArray.last ?? "값없음")")
                self.contributionCollectionView.reloadData()
            }else{
                print("//날짜 새로고침 할 것 없음: 예전\(realOldDateArray.last ?? "값없음"), 새것\(realNewValueArray.last ?? "값없음")")
            }
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
        
        self.contributionCollectionView.backgroundColor = .clear
        self.getMonthTextForLabel()
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
        
        guard let isRealSignIn = isSignedIn else {return}
        if isRealSignIn == true {
            guard let realCurrentGitHubID:String = self.currentGitHubID else {return}
            self.updateContributionDatasOf(gitHubID: realCurrentGitHubID)
        }else{
            print("//로그아웃상태")
            self.widgetStatusLabel.text = "Open GITGET to get your contributions :)\n\n  • Double tap to open \n  • Single tap to refresh".localized
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
        self.dataActivityIndicator.stopAnimating()
        let myAppUrl = URL(string: "main-screen://")!
        extensionContext?.open(myAppUrl, completionHandler: { (success) in
            if (!success) {
                print("///ERROR: failed to open app from Today Extension")
            }
        })
    }
    
    //Widget을 한번 탭하면 GitGet이 새로고침 됨
    @IBAction func toRefershGitGetApp(_ sender: UITapGestureRecognizer) {
        self.dataActivityIndicator.startAnimating()
        guard let realGitHubID:String = self.currentGitHubID else {return}
        self.updateContributionDatasOf(gitHubID: realGitHubID)
    }
    
    //위젯의 크기에 따라 표현하고 싶은 내용이 다를 때 사용. 현재 깃젯은 compact 사이즈만 제공함
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            /* .compact는 default 값으로, 높이 값이 정해져 있어 조절이 불가능 하다. (fixed 110px)
             해당 default 값은 기기에 상관없이 모두 동일하다. 즉 위젯의 크기는 기기의 크기에 따라 width 만 변화한다.
             .expanded 를 사용하지 않고 .compact의 높이가 변화하는 예외 사항이 있다.
             iPhone의 Setting(설정) > General(일반) > Accessibility(손쉬운 사용) > Larger Text 의 하단에 있는 바를 통해 조절하는 경우다.
             고정된 높이(110px)에서 글자를 크게 조절할 수록 높이가 늘어나고, 작게 조절할 수록 높이는 줄어든다.
             TODO:- 정확한 수치를 반영한 셀 조절은 추후 업데이트에 필요한 사항임
            */
            self.preferredContentSize = maxSize
        }
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
    
    //각 월의 첫 날에 해당하는 셀의 x좌표와, 각 월별Label의 x좌표를 맞추는 함수
    func setMonthLabelXPositions(with xPositionArray:[CGFloat]) {
        let screenWidth:CGFloat = self.view.frame.width
        switch screenWidth {
        case 398.0: //iPhone Plus
            if xPositionArray[6] < 351 {
                self.currentMonthLabelLeadingConstraint.constant = xPositionArray[6]
            }else{
                self.currentMonthLabel.isHidden = true
            }
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[5]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[4]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.fifthMonthLabelLeadingConstraint.constant = xPositionArray[1]
            if xPositionArray[0] > 12 {
                self.sixthMonthLabelLeadingConstraint.constant = xPositionArray[0]
            }else{
                self.sixthPreviousMonthLabel.isHidden = true
            }
        case 359.0: //iPhone 6,7,8,X
                if xPositionArray[5] < 311 {
                    self.currentMonthLabelLeadingConstraint.constant = xPositionArray[5]
                }else{
                    self.currentMonthLabel.isHidden = true
                }
                self.firstMonthLabelLeadingConstraint.constant = xPositionArray[4]
                self.secondMonthLabelLeadingConstraint.constant = xPositionArray[3]
                self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[2]
                self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[1]
                if xPositionArray[0] > 12 {
                    self.fifthMonthLabelLeadingConstraint.constant = xPositionArray[0]
                }else{
                    self.fifthPreviousMonthLabel.isHidden = true
                }
                self.sixthPreviousMonthLabel.isHidden = true
        case 304.0: //iPhone 4,5,SE
            
            if xPositionArray[4] < 251 {
                self.currentMonthLabelLeadingConstraint.constant = xPositionArray[4]
            }else{
                self.currentMonthLabel.isHidden = true
            }
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[1]
            if xPositionArray[0] > 12 {
                self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[0]
            }else{
                self.fourthPreviousMonthLabel.isHidden = true
            }
            self.fifthPreviousMonthLabel.isHidden = true
            self.sixthPreviousMonthLabel.isHidden = true
        default:
            self.widgetStatusLabel.text = "Unable into Load"
        }
    }
    
    //GitHubAPIManager를 통해 가져온 dateArray의 index 중, #번째 전월의 첫날에 해당하는 index를 출력하는 함수
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
        
        guard let realDateArray = self.dateArray,
            let indexPath = realDateArray.index(of: previousDateString) else {return 0}
        return indexPath
    }
    
    //GitHubAPIManager를 통한 데이터 업데이트
    func updateContributionDatasOf(gitHubID:String) {
        GitHubAPIManager.sharedInstance.getContributionsColorCodeArray(gitHubID: gitHubID) { (contributionsColorCodeArray) in
            self.hexColorCodesArray = contributionsColorCodeArray
        }
        
        GitHubAPIManager.sharedInstance.getContributionsDateArray(gitHubID: gitHubID) { (contributionsDateArray) in
            self.dateArray = contributionsDateArray
        }
    }
    
}

//MARK:- extension_CollectionView Delegate & DataSource
extension TodayViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let screenSize:CGFloat = self.view.frame.width
        
        guard let realDateArray = self.dateArray else {print("//날짜 값이 들어오지 않았습니다"); return 0}
        switch screenSize {
        case 398.0: //iPhone Plus
            return realDateArray.count - 141
        case 359.0: //iPhone, X
            return realDateArray.count - 162
        case 304.0: //iPhone SE, 4
            return realDateArray.count - 197
        default:
            self.widgetStatusLabel.text = "Unable to Load"
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        if let realHexColorCodes:[String] = self.hexColorCodesArray {
            let screenSize:CGFloat = self.view.frame.width
            switch screenSize {
            case 398.0: //iPhone Plus
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 141])
                
                for index in 0...6 {
                    if (indexPath.row + 141) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                    }
                }
            case 359.0: //iPhone, X
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 162])
                
                for index in 0...5 {
                    if (indexPath.row + 162) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                    }
                }
            case 304.0: //iPhone SE, 4
                cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + 197])
                
                for index in 0...4 {
                    if (indexPath.row + 197) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                        let xPosition:CGFloat = cell.frame.origin.x
                        self.xPositionForMonthLabels.append(xPosition)
                    }
                }
            default:
                self.widgetStatusLabel.text = "Unable to Load"
            }
        }
        return cell
    }
    
    
    //MARK:- 리팩토링 저장소_과거 작성했었으나 개선 또는 보류의 목적으로 주석처리한 코드들
    
    /*TODO:- widgetPerformUpdate 사용법을 이해하지 못하고 있음. 스터디 후 활용할 것
     func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
     let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")
     guard let contributionDatas:[String] = userDefaults?.object(forKey: "ContributionsDatas") as? [String],
     let contributionDates:[String] = userDefaults?.object(forKey: "ContributionsDates") as? [String],
     let todayContribution:String = userDefaults?.object(forKey: "TodayContributions") as? String else {return}
     
     //        self.expandedUserStatusLabel.text! = "Cheer up! \(todayContribution) contributions today!"
     
     print("//TE_widgetPerformUpdate:\(NCUpdateResult.newData)")
     
     completionHandler(NCUpdateResult.newData)
     }
     */
    
    /* Delete: 현재 시간을 매번 확인하는 것보다, 받아오는 데이터의 수를 날짜 수로 인식하는 것이 오류가 없을 것이라 판단하여 삭제하였음.
     //현재 Local 시간을 UTC 기준으로 변환하여 요일수로 반환하기
     //GitHub: Contributions are timestamped according to Coordinated Universal Time (UTC) rather than your local time zone.
     //참고: https://help.github.com/articles/why-are-my-contributions-not-showing-up-on-my-profile/
     func getUTCWeekdayFromLocalTime(){
     let date:Date = Date()
     let dateFormatter:DateFormatter = DateFormatter()
     guard let timeZone:TimeZone = TimeZone(abbreviation: "UTC"),
     let utcWeekDay = dateFormatter.calendar.dateComponents(in: timeZone, from: date).weekday else {return}
     self.utcWeekdayNumber = utcWeekDay
     
     print("//getUTCWeekdayFromLocalTime 함수 실행: 현재는 \(utcWeekDay)번째 요일입니다.")
     }
     */
    
}

//MARK:- extension_색상 hexcode 를 입력하면 해당 색으로 출력
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

//MARK:- extension_특정 String을 한국어 localization 할고자 할 때 사용
extension String {
    var localized:String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

