//
//  GitGetTodayViewController.swift
//  GitGetTodayExtension
//
//  Created by Bo-Young PARK on 13/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import NotificationCenter

class GitGetTodayViewController: UIViewController, NCWidgetProviding {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    
    //월을 나타내는 Label: 총 12개
    @IBOutlet weak var monthLabelOneByTwelve: UILabel!
    @IBOutlet weak var monthLabelTwoByTwelve: UILabel!
    @IBOutlet weak var monthLabelThreeByTwelve: UILabel!
    @IBOutlet weak var monthLabelFourByTwelve: UILabel!
    @IBOutlet weak var monthLabelFiveByTwelve: UILabel!
    @IBOutlet weak var monthLabelSixByTwelve: UILabel!
    @IBOutlet weak var monthLabelSevenByTwelve: UILabel!
    @IBOutlet weak var monthLabelEightByTwelve: UILabel!
    @IBOutlet weak var monthLabelNineByTwelve: UILabel!
    @IBOutlet weak var monthLabelTenByTwelve: UILabel!
    @IBOutlet weak var monthLabelElevenByTwelve: UILabel!
    @IBOutlet weak var monthLabelTwelveByTwelve: UILabel!
    
    //요일을 나타내는 Label: 총 3개
    @IBOutlet weak var mondayLabel: UILabel!
    @IBOutlet weak var wednesdayLabel: UILabel!
    @IBOutlet weak var fridayLabel: UILabel!
    
    //Contribution을 나타내는 CollectionView
    @IBOutlet weak var contributionsCollectionView: UICollectionView!
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        contributionsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "contributions")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}

//CollectionView 관련부분 구현할 부분
extension GitGetTodayViewController:UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 366
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributions", for: indexPath)
        
        cell.backgroundColor = .black
        
        return cell
    }
}
