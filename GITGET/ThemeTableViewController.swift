//
//  ThemeTableViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 08/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import NotificationCenter

enum ThemeName:Int {
    case gitHubOriginal
    case blackAndWhite
    case jejuOceanBlue
    case winterBurgundy
    case halloweenOrange
    case ginkgoYellow
    case freeStyle
    case christmasEdition
}

class ThemeTableViewController: UITableViewController {

    let cellTitleData:[String] = ["GitHub Original".localized,
                                  "Black And White".localized,
                                  "Jeju Ocean Blue".localized,
                                  "Winter Burgundy".localized,
                                  "Halloween Orange".localized,
                                  "Ginkgo Yellow".localized,
                                  "Freestyle".localized,
                                  "Christmas Edition".localized]
    let cellImageData:[UIImage] = [#imageLiteral(resourceName: "Theme_GitHubOriginal"), #imageLiteral(resourceName: "Theme_BlackAndWhite"), #imageLiteral(resourceName: "Theme_JejuOceanBlue"), #imageLiteral(resourceName: "Theme_WinterBurgundy"), #imageLiteral(resourceName: "Theme_HalloweenOrange"), #imageLiteral(resourceName: "Theme_GinkgoYellow"), #imageLiteral(resourceName: "Theme_FreeStyle"), #imageLiteral(resourceName: "Theme_ChristmasEdition")]
    var currentTheme = ThemeName(rawValue: (UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ThemeNameRawValue") as? Int) ?? 0) {
        willSet(newValue){
            if currentTheme != newValue {
                currentTheme = newValue
                self.tableView.reloadData()
            }
            print("현재 테마: \(currentTheme)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellTitleData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let themeCell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "themeCell") as! CustomTableViewCell
        
        if currentTheme?.rawValue == indexPath.row {
            themeCell.accessoryType = .checkmark
        }else{
            themeCell.accessoryType = .none
        }
        
        DispatchQueue.main.async {
            themeCell.themeTitleLabel.text = self.cellTitleData[indexPath.row]
            themeCell.imageView?.image = self.cellImageData[indexPath.row]
            themeCell.setNeedsLayout()
        }

        return themeCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentTheme = ThemeName(rawValue: indexPath.row)
        UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.set(indexPath.row, forKey: "ThemeNameRawValue")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
    
}
