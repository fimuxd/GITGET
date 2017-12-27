//
//  RealmModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 17/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import Foundation
import RealmSwift

class Colleague: Object {
    @objc dynamic var gitHubUserName:String = ""
    @objc dynamic var htmlValue:String = ""
    @objc dynamic var nickname:String = ""
    @objc dynamic var uuid:String = UUID().uuidString
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}

class AccessToken: Object {
    @objc dynamic var token:String = ""
}

