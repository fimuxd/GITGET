//
//  TipJarViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 27/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit

class TipJarViewController: UIViewController {

    let rowTitles:[String] = ["Chocolate bar", "A Cup of Coffee", "Burger and Fries"]
    let rowSubtitles:[String] = ["$0.99", "$3.99", "$9.99"]

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goToGitHubAction(_ sender: UIButton) {
    }
    
    @IBAction func goToFacebookAction(_ sender: UIButton) {
    }
    
    @IBAction func goToLinkedInAction(_ sender: UIButton) {
    }
    
}

extension TipJarViewController:UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Choose Donation Plan"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "donationCell") as! UITableViewCell
        
        cell.textLabel?.text = self.rowTitles[indexPath.row]
        cell.detailTextLabel?.text = self.rowSubtitles[indexPath.row]
        cell.imageView?.image = UIImage(named: "donation\(indexPath.row)")
        cell.imageView?.contentMode = .scaleAspectFit
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
}
