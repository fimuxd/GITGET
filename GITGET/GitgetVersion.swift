//
//  GitgetVersion.swift
//  GITGET
//
//  Created by 장인수 on 2017. 12. 14..
//  Copyright © 2017년 Bo-Young PARK. All rights reserved.
//

import Foundation


class GitgetVersion : NSObject {
    var lastest_version_code: String        /** 최신버젼 코드     */
    var lastest_version_name: String        /** 최신버젼 명      */
    var minimum_version_code: String        /** 최소버젼 코드     */
    var minimum_version_name: String        /** 최소벼젼 명      */
    var force_update_message: String        /** 강제업데이트 메세지 */
    var optional_update_message: String     /** 선택업데이트 메세지 */
    
    
    init(lastest_version_code:String, lastest_version_name:String,
         minimum_version_code:String, minimum_version_name:String,
         force_update_message:String, optional_update_message:String) {
        
        self.lastest_version_code       = lastest_version_code
        self.lastest_version_name       = lastest_version_name
        self.minimum_version_code       = minimum_version_code
        self.minimum_version_name       = minimum_version_name
        self.force_update_message       = force_update_message
        self.optional_update_message    = optional_update_message
    }
    
    convenience override init() {
        self.init(lastest_version_code: "", lastest_version_name: "",
                  minimum_version_code: "", minimum_version_name: "",
                  force_update_message: "", optional_update_message: "")
    }
}
