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
    
    //MonthTextLabel
    @IBOutlet weak var currentMonthLabel: UILabel!
    @IBOutlet weak var firstPreviousMonthLabel: UILabel!
    @IBOutlet weak var secondPreviousMonthLabel: UILabel!
    @IBOutlet weak var thirdPreviousMonthLabel: UILabel!
    @IBOutlet weak var fourthPreviousMonthLabel: UILabel!
    @IBOutlet weak var fifthPreviousMonthLabel: UILabel!
    @IBOutlet weak var sixthPreviousMonthLabel: UILabel!
    @IBOutlet weak var seventhPreviousMonthLabel: UILabel!
    
    //MonthTextLabelAttribute
    @IBOutlet weak var currentMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var thirdMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fourthMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fifthMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sixthMonthLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var seventhMonthLabelLeadingConstraint: NSLayoutConstraint!
    
    //기기별 콜렉션뷰 출력을 위한 Constraints
    //For Height
    @IBOutlet weak var monthLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var monthLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    //ForWidth
    @IBOutlet weak var weekdayLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var weekdayLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewWidthConstraint: NSLayoutConstraint!
    //요일 라벨
    @IBOutlet weak var wedToFriSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var wedToMonSpiceConstraint: NSLayoutConstraint!
    
    //UILabel_.상태확인바
    @IBOutlet weak var widgetStatusLabel: UILabel!
    
    //UICollectionView
    @IBOutlet weak var contributionCollectionView: UICollectionView!
    var collectionViewSectionInset:UIEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    let minimumCellSpacing:CGFloat = 1.2
    
    //UIActivityIndicator
    @IBOutlet weak var dataActivityIndicator: UIActivityIndicatorView!
    
    //깃젯 앱과 통신하여 가져오는 UserDefaults 값
    let isSignedIn:Bool? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "isSigned") as? Bool
    let currentGitHubID:String? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String
    let themeRawValue:Int? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ThemeNameRawValue") as? Int
    
    //MARK:- 월별 Label 위치 목록 가져옴
    var xPositionForMonthLabels:Set<CGFloat> = [] {
        willSet(newValue){
            print("//엑스: 새로운 값이 들어왔습니다. ")
            if xPositionForMonthLabels.sorted() != newValue.sorted() {
                self.xPositionForMonthLabels = newValue
                
                DispatchQueue.main.async {
                    self.currentMonthLabel.isHidden = false
                    self.firstPreviousMonthLabel.isHidden = false
                    self.secondPreviousMonthLabel.isHidden = false
                    self.thirdPreviousMonthLabel.isHidden = false
                    self.fourthPreviousMonthLabel.isHidden = false
                    self.fifthPreviousMonthLabel.isHidden = false
                    self.sixthPreviousMonthLabel.isHidden = false
                    self.seventhPreviousMonthLabel.isHidden = false
                    
                    self.setMonthLabelXPositions(with: self.xPositionForMonthLabels.sorted(by: >))
                }
            }
        }
    }
    
    //Contributions 관련 Data 통신: 앱 설치 및 로그인 후 최초 1회만 앱을 통해 통신한 값을 띄우고, 이후부터는 위젯이 직접통신하는 구조
    //MARK:- 색상 코드 목록 가져옴
    var hexColorCodesArray = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDatas") as? [String] {
        willSet(newValue){
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults"),
                let realOldValue = userDefaults.value(forKey: "ContributionsDatas") as? [String],
                let realNewValue = newValue else {return}
            userDefaults.synchronize()
            if realOldValue != realNewValue {
                self.hexColorCodesArray = newValue
                userDefaults.setValue(newValue, forKey: "ContributionsDatas")
                print("//색상 업데이트 됨: 예전\(hexColorCodesArray!.last ?? "값없음"), 새것\(newValue!.last ?? "값없음")")
                self.contributionCollectionView.reloadData()
            }else{
                print("//색상 새로고침 할 것 없음: 예전\(realOldValue.last ?? "값없음"), 새것\(realNewValue.last ?? "값없음")")
                self.dataActivityIndicator.stopAnimating()
            }
        }
    }
    
    //MARK:- 날짜목록 가져옴
    var dateArray = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ContributionsDates") as? [String] {
        willSet(newValue){
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults"),
                let realOldValue = userDefaults.value(forKey: "ContributionsDates") as? [String],
                let realNewValue = newValue else {return}
            userDefaults.synchronize()
            if realOldValue != realNewValue {
                self.dateArray = newValue
                userDefaults.setValue(newValue, forKey: "ContributionsDates")
                print("//날짜 업데이트 됨: 예전\(dateArray!.last ?? "값없음"), 새것\(newValue!.last ?? "값없음")")
                self.contributionCollectionView.reloadData()
            }else{
                print("//날짜 새로고침 할 것 없음: 예전\(realOldValue.last ?? "값없음"), 새것\(realNewValue.last ?? "값없음")")
                self.dataActivityIndicator.stopAnimating()
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
        let collectionViewLayout = contributionCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        collectionViewLayout?.sectionInset = self.collectionViewSectionInset
        collectionViewLayout?.invalidateLayout()
        self.contributionCollectionView.isHidden = true
        
        self.currentMonthLabel.isHidden = true
        self.firstPreviousMonthLabel.isHidden = true
        self.secondPreviousMonthLabel.isHidden = true
        self.thirdPreviousMonthLabel.isHidden = true
        self.fourthPreviousMonthLabel.isHidden = true
        self.fifthPreviousMonthLabel.isHidden = true
        self.sixthPreviousMonthLabel.isHidden = true
        self.seventhPreviousMonthLabel.isHidden = true
        
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
            self.seventhPreviousMonthLabel.isHidden = true
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
    
    //MARK:- Widget을 한번 탭하면 GitGet이 새로고침 됨
    @IBAction func toRefershGitGetApp(_ sender: UITapGestureRecognizer) {
        self.dataActivityIndicator.startAnimating()
        guard let realGitHubID:String = self.currentGitHubID else {return}
        self.updateContributionDatasOf(gitHubID: realGitHubID)
    }
    
    //MARK:- 위젯의 크기에 따라 표현하고 싶은 내용이 다를 때 사용. (현재 깃젯은 compact만 지원)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            /* .compact는 default 값으로, 높이 값이 정해져 있어 조절이 불가능 하다. (fixed 110px)
             해당 default 값은 기기에 상관없이 모두 동일하다. 즉 위젯의 크기는 기기의 크기에 따라 width 만 변화한다.
             .expanded 를 사용하지 않고 .compact의 높이가 변화하는 예외 사항이 있다.
             iPhone의 Setting(설정) > General(일반) > Accessibility(손쉬운 사용) > Larger Text 의 하단에 있는 바를 통해 조절하는 경우다.
             고정된 높이(110px)에서 글자를 크게 조절할 수록 높이가 늘어나고, 작게 조절할 수록 높이는 줄어든다.
             글씨 사이즈별로 위젯 높이는 8가지로 변화한다.
             95, 100, 105, 110, 130, 145, 170, 200
             */
            self.preferredContentSize = maxSize
        }
    }
    
    //MARK:- 월별 텍스트(Jan~Dec) 가져오기
    func getMonthTextForLabel() {
        let date:Date = Date()
        let dateFormatter:DateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "MMM"
        dateFormatter.locale = Locale(identifier: "en_US") as Locale
        
        var dateArray:[Date] = [date]
        for count in 1...7 {
            let previousDate:Date = Date(timeInterval: -2592200 * fabs(Double(count)), since: date)
            dateArray.append(previousDate)
        }
        
        var monthStringArray:[String] = dateArray.map { (date) -> String in
            return dateFormatter.string(from: date)
        }
        
        self.currentMonthLabel.text = monthStringArray[0]
        self.firstPreviousMonthLabel.text = monthStringArray[1]
        self.secondPreviousMonthLabel.text = monthStringArray[2]
        self.thirdPreviousMonthLabel.text = monthStringArray[3]
        self.fourthPreviousMonthLabel.text = monthStringArray[4]
        self.fifthPreviousMonthLabel.text = monthStringArray[5]
        self.sixthPreviousMonthLabel.text = monthStringArray[6]
        self.seventhPreviousMonthLabel.text = monthStringArray[7]
    }
    
    //MARK:- 각 월의 첫 날에 해당하는 셀의 x좌표와, 각 월별Label의 x좌표를 맞추는 함수
    func setMonthLabelXPositions(with xPositionArray:[CGFloat]) {
        if xPositionArray.count > 0 && xPositionArray.count < 4 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray.last!
            
            DispatchQueue.main.async {
                self.thirdPreviousMonthLabel.isHidden = true
                self.fourthPreviousMonthLabel.isHidden = true
                self.fifthPreviousMonthLabel.isHidden = true
                self.sixthPreviousMonthLabel.isHidden = true
                self.seventhPreviousMonthLabel.isHidden = true
            }
            
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.secondPreviousMonthLabel.isHidden = true
                }
            }
        }else if xPositionArray.count == 4 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray.last!
            
            DispatchQueue.main.async {
                self.fourthPreviousMonthLabel.isHidden = true
                self.fifthPreviousMonthLabel.isHidden = true
                self.sixthPreviousMonthLabel.isHidden = true
                self.seventhPreviousMonthLabel.isHidden = true
            }
            
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.thirdPreviousMonthLabel.isHidden = true
                }
            }
        }else if xPositionArray.count == 5 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.fourthMonthLabelLeadingConstraint.constant = xPositionArray.last!
            DispatchQueue.main.async {
                self.fifthPreviousMonthLabel.isHidden = true
                self.sixthPreviousMonthLabel.isHidden = true
                self.seventhPreviousMonthLabel.isHidden = true
            }
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.fourthPreviousMonthLabel.isHidden = true
                }
            }
        }else if xPositionArray.count == 6 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[4]
            self.fifthMonthLabelLeadingConstraint.constant = xPositionArray.last!
            DispatchQueue.main.async {
                self.sixthPreviousMonthLabel.isHidden = true
                self.seventhPreviousMonthLabel.isHidden = true
            }
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.fifthPreviousMonthLabel.isHidden = true
                }
            }
        }else if xPositionArray.count == 7 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[4]
            self.fifthMonthLabelLeadingConstraint.constant = xPositionArray[5]
            self.sixthMonthLabelLeadingConstraint.constant = xPositionArray.last!
            DispatchQueue.main.async {
                self.seventhPreviousMonthLabel.isHidden = true
            }
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.sixthPreviousMonthLabel.isHidden = true
                }
            }
        }else if xPositionArray.count > 7 {
            self.currentMonthLabelLeadingConstraint.constant = xPositionArray.first!
            self.firstMonthLabelLeadingConstraint.constant = xPositionArray[1]
            self.secondMonthLabelLeadingConstraint.constant = xPositionArray[2]
            self.thirdMonthLabelLeadingConstraint.constant = xPositionArray[3]
            self.fourthMonthLabelLeadingConstraint.constant = xPositionArray[4]
            self.fifthMonthLabelLeadingConstraint.constant = xPositionArray[5]
            self.sixthMonthLabelLeadingConstraint.constant = xPositionArray[6]
            self.seventhMonthLabelLeadingConstraint.constant = xPositionArray[7]
            
            if xPositionArray.last! < self.weekdayLabelWidthConstraint.constant + collectionViewLeadingConstraint.constant {
                DispatchQueue.main.async {
                    self.seventhPreviousMonthLabel.isHidden = true
                }
            }
        }
        
        if xPositionArray.first! > self.view.frame.width - self.collectionViewTrailingConstraint.constant {
            self.currentMonthLabel.isHidden = true
        }
        
    }
    
    //MARK:- GitHubAPIManager를 통해 가져온 dateArray의 index 중, #번째 전월의 첫날에 해당하는 index를 출력하는 함수
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
    
    //MARK:- GitHubAPIManager를 통한 데이터 업데이트
    func updateContributionDatasOf(gitHubID:String) {
        GitHubAPIManager.sharedInstance.getContributionsColorCodeArray(gitHubID: gitHubID, theme: ThemeName(rawValue: self.themeRawValue ?? 0)) { (contributionsColorCodeArray) in
            print("//왜안되: \(contributionsColorCodeArray)")
            self.hexColorCodesArray = contributionsColorCodeArray
        }
        
        GitHubAPIManager.sharedInstance.getContributionsDateArray(gitHubID: gitHubID) { (contributionsDateArray) in
            self.dateArray = contributionsDateArray
        }
        
        if self.xPositionForMonthLabels.count != 0 {
            self.setMonthLabelXPositions(with: self.xPositionForMonthLabels.sorted(by: >))
        }
    }
    
    //MARK:- UICollectionView Cell 크기를 계산하여 글씨를 출력해주는 함수
    func  setUILabelSizePerFont() {
        let widgetWidth:CGFloat = self.view.frame.width
        let widgetHeight:CGFloat = self.view.frame.height
        
        //높이에 따라 글자 크기 변화
        if widgetHeight > 144 {
            for view in self.view.subviews {
                if view.isKind(of: UILabel.classForCoder()) {
                    let label = view as? UILabel
                    label?.font = label?.font.withSize(15)
                }
                self.weekdayLabelWidthConstraint.constant = 15
                self.monthLabelHeightConstraint.constant = 18
            }
        }else if widgetHeight > 110 && widgetHeight < 145 {
            for view in self.view.subviews {
                if view.isKind(of: UILabel.classForCoder()) {
                    let label = view as? UILabel
                    label?.font = label?.font.withSize(12)
                }
                self.weekdayLabelWidthConstraint.constant = 12.33
                self.monthLabelHeightConstraint.constant = 14.4
            }
        }else if widgetHeight < 111 {
            for view in self.view.subviews {
                if view.isKind(of: UILabel.classForCoder()) {
                    let label = view as? UILabel
                    label?.font = label?.font.withSize(10)
                }
                
                self.weekdayLabelWidthConstraint.constant = 11
                self.monthLabelHeightConstraint.constant = 12
            }
        }
    }
    
    //MARK: 콜렉션뷰 셀 너비(=높이) 출력해주는 함수
    func getCollectionViewCellWidth() -> CGFloat {
        let widgetWidth:CGFloat = self.view.frame.width
        let widgetHeight:CGFloat = self.view.frame.height
        
        self.setUILabelSizePerFont()
    
        let collectionViewHeight:CGFloat = widgetHeight - (self.monthLabelTopConstraint.constant + self.monthLabelHeightConstraint.constant) - (self.collectionViewTopConstraint.constant + self.collectionViewBottomConstraint.constant) - (self.collectionViewSectionInset.top + self.collectionViewSectionInset.bottom)
        
        let cellHeight:CGFloat = (collectionViewHeight - (self.minimumCellSpacing * 8)) / 7
        
        return cellHeight
    }
    
    //MARK:- UICollectionView Cell 크기를 계산하여 화면에 표시되는 일수를 출력하는 함수
    func getMarkableDaysCount() -> Int {
        let widgetWidth:CGFloat = self.view.frame.width
        let widgetHeight:CGFloat = self.view.frame.height
        
        self.setUILabelSizePerFont()
        
        let collectionViewWidth:CGFloat = widgetWidth - (self.weekdayLabelLeadingConstraint.constant + self.weekdayLabelWidthConstraint.constant) - (self.collectionViewLeadingConstraint.constant + self.collectionViewTrailingConstraint.constant) - (self.collectionViewSectionInset.left + self.collectionViewSectionInset.right)
        let collectionViewHeight:CGFloat = widgetHeight - (self.monthLabelTopConstraint.constant + self.monthLabelHeightConstraint.constant) - (self.collectionViewTopConstraint.constant + self.collectionViewBottomConstraint.constant) - (self.collectionViewSectionInset.top + self.collectionViewSectionInset.bottom)
        
        let cellHeight:CGFloat = (collectionViewHeight - (self.minimumCellSpacing * 6)) / 7
        let numberOfWeek:CGFloat = ((collectionViewWidth - self.minimumCellSpacing) / (cellHeight + self.minimumCellSpacing)).rounded(.up)
        let markableNumberOfDays:Int = Int(53 - numberOfWeek) * 7
        
        self.collectionViewHeightConstraint.constant = collectionViewHeight + (self.collectionViewSectionInset.top + self.collectionViewSectionInset.bottom)
        self.collectionViewWidthConstraint.constant = collectionViewWidth + (self.collectionViewSectionInset.left + self.collectionViewSectionInset.right)
        self.wedToFriSpaceConstraint.constant = cellHeight + self.minimumCellSpacing * 2
        self.wedToMonSpiceConstraint.constant = cellHeight + self.minimumCellSpacing * 2
        
        DispatchQueue.main.async {
            self.contributionCollectionView.isHidden = false
        }
        
        return markableNumberOfDays
    }
    
    
}

//MARK:- extension_CollectionView Delegate & DataSource
extension TodayViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK:- numberOfItemsInSection: 셀 개수 출력 & collectionView 높이
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let markableNumberOfDays:Int = self.getMarkableDaysCount()
        
        guard let realHexCodeArray = self.hexColorCodesArray else {
            self.widgetStatusLabel.text = "Open GITGET to get your contributions :)\n\n  • Double tap to open \n  • Single tap to refresh".localized
            self.dataActivityIndicator.stopAnimating()
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
            self.seventhPreviousMonthLabel.isHidden = true
            
            return 0}
    
        return realHexCodeArray.count - markableNumberOfDays
    }
    
    //MARK:- cellForItemAt: 각 셀의 색상 설정 & 월별 첫날에 해당하는 셀의 xPosition 설정
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        
        if let realHexColorCodes:[String] = self.hexColorCodesArray {
            let markableNumberOfDays:Int = self.getMarkableDaysCount()
            
            cell.backgroundColor = UIColor(hex: realHexColorCodes[indexPath.row + markableNumberOfDays])
            
            for index in 0...7 {
                if (indexPath.row + markableNumberOfDays) == self.findIndexPathForFirstOf(previousMonthNumber: index) {
                    let xPosition:CGFloat = cell.frame.origin.x
                    self.xPositionForMonthLabels.insert(xPosition)
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth:CGFloat = self.getCollectionViewCellWidth()
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    //MARK:- 리팩토링 저장소_과거 작성했었으나 개선 또는 보류의 목적으로 주석처리한 코드들
    
    //TODO:- widgetPerformUpdate 사용법을 이해하지 못하고 있음. 스터디 후 활용할 것
     func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        guard let realGitHubID:String = self.currentGitHubID else {print("로그인한 값이 없음"); return}
        
        //색상코드 가져오기
        
        
        
     completionHandler(NCUpdateResult.newData)
     }
    
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
    
    /* Delete: 정신나간 하드코딩이었다. :p
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
     */
    
    
    /* Delete: 콜렉션뷰를 이해하고 조작하는 것이 힘들었다. 일일히 다 시뮬레이터 해가면서 계산했는데 당연히 컴퓨팅이 정확하다.
     switch widgetWidth { //접속한 기기의 종류에 따라 스위치
     case 398.0: //iPhone Plus
     if widgetHeight > 177.0 { //현재 위젯 높이(유저별 셋팅에서 글자 크기)에 따라 구분
     return CGSize(width: 24.0, height: 24.0)
     }else if widgetHeight > 169.0 && widgetHeight < 177.0 {
     return CGSize(width: 19.5, height: 19.5)
     }else if widgetHeight > 144.0 && widgetHeight < 169.0 {
     return CGSize(width: 15.1, height: 15.1)
     }else if widgetHeight > 129.0 && widgetHeight < 144.0 {
     return CGSize(width: 13.6, height: 13.6)
     }else if widgetHeight > 119.0 && widgetHeight < 129.0 {
     return CGSize(width: 11.8, height: 11.8)
     }else if widgetHeight > 109.0 && widgetHeight < 119.0 {
     return CGSize(width: 11.4, height: 11.4)
     }else if widgetHeight > 104.0 && widgetHeight < 109.0 {
     return CGSize(width: 9.5, height: 9.5)
     }else{
     return CGSize(width: 9.2, height: 9.2)
     }
     case 359.0: //iPhone 6,7,8,X
     if widgetHeight > 178.0 { //현재 위젯 높이(유저별 셋팅에서 글자 크기)에 따라 구분
     return CGSize(width: 12.0, height: 12.0)
     }else if widgetHeight > 177.0 && widgetHeight < 178.0 {
     return CGSize(width: 11.5, height: 11.5)
     }else if widgetHeight > 169.0 && widgetHeight < 177.0 {
     return CGSize(width: 11.0, height: 11.0)
     }else if widgetHeight > 144.0 && widgetHeight < 169.0 {
     return CGSize(width: 10.5, height: 10.5)
     }else if widgetHeight > 129.0 && widgetHeight < 144.0 {
     return CGSize(width: 10.0, height: 10.0)
     }else if widgetHeight > 119.0 && widgetHeight < 129.0 {
     return CGSize(width: 9.5, height: 9.5)
     }else if widgetHeight > 109.0 && widgetHeight < 119.0 {
     return CGSize(width: 9.0, height: 9.0)
     }else if widgetHeight > 104.0 && widgetHeight < 109.0 {
     return CGSize(width: 8.5, height: 8.5)
     }else if widgetHeight > 99.0 && widgetHeight < 104.0 {
     return CGSize(width: 8.0, height: 8.0)
     }else{
     return CGSize(width: 7.5, height: 7.5)
     }
     case 304.0: //iPhone SE
     if widgetHeight > 178.0 { //현재 위젯 높이(유저별 셋팅에서 글자 크기)에 따라 구분
     return CGSize(width: 12.0, height: 12.0)
     }else if widgetHeight > 177.0 && widgetHeight < 178.0 {
     return CGSize(width: 11.5, height: 11.5)
     }else if widgetHeight > 169.0 && widgetHeight < 177.0 {
     return CGSize(width: 11.0, height: 11.0)
     }else if widgetHeight > 144.0 && widgetHeight < 169.0 {
     return CGSize(width: 10.5, height: 10.5)
     }else if widgetHeight > 129.0 && widgetHeight < 144.0 {
     return CGSize(width: 10.0, height: 10.0)
     }else if widgetHeight > 119.0 && widgetHeight < 129.0 {
     return CGSize(width: 9.5, height: 9.5)
     }else if widgetHeight > 109.0 && widgetHeight < 119.0 {
     return CGSize(width: 9.0, height: 9.0)
     }else if widgetHeight > 104.0 && widgetHeight < 109.0 {
     return CGSize(width: 8.5, height: 8.5)
     }else if widgetHeight > 99.0 && widgetHeight < 104.0 {
     return CGSize(width: 8.0, height: 8.0)
     }else{
     return CGSize(width: 7.5, height: 7.5)
     }
     default:
     return CGSize(width: 0, height: 0)
     }
     */
    
    /* Delete: 콜렉션뷰를 이해하고 조작하는 것이 힘들었다. 일일히 다 시뮬레이터 해가면서 계산했는데 당연히 컴퓨팅이 정확하다.
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
     let widgetWidth:CGFloat = self.view.frame.width
     let widgetHeight:CGFloat = self.view.frame.height
     
     if widgetWidth == 359.0 {
     let cellHeight:CGFloat = (widgetHeight - self.monthLabelHeightConstraint.constant - self.collectionViewTopConstraint.constant - self.collectionViewBottomConstraint.constant - 4 - 9.6) / 7
     return CGSize(width: cellHeight, height: cellHeight)
     }else{
     if widgetHeight > 177.0 { //현재 위젯 높이(유저별 셋팅에서 글자 크기)에 따라 구분
     return CGSize(width: 24.0, height: 24.0)
     }else if widgetHeight > 169.0 && widgetHeight < 177.0 {
     return CGSize(width: 19.5, height: 19.5)
     }else if widgetHeight > 144.0 && widgetHeight < 169.0 {
     return CGSize(width: 15.1, height: 15.1)
     }else if widgetHeight > 129.0 && widgetHeight < 144.0 {
     return CGSize(width: 13.6, height: 13.6)
     }else if widgetHeight > 119.0 && widgetHeight < 129.0 {
     return CGSize(width: 11.8, height: 11.8)
     }else if widgetHeight > 109.0 && widgetHeight < 119.0 {
     return CGSize(width: 11.4, height: 11.4)
     }else if widgetHeight > 104.0 && widgetHeight < 109.0 {
     return CGSize(width: 9.5, height: 9.5)
     }else{
     return CGSize(width: 9.2, height: 9.2)
     }
     }
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

//MARK: Bold Text 여부 확인하는 목적
extension UIFont {
    var isBold:Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
}

