//
//  Constance.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import Foundation

struct SystemConstance {
    struct Email {
        static let emailAddress = "me@boyoung.dev"
        static let subject = "[GITGET] Feedback for GITGET"
        static let body = """

        Thanks for your feedback!
        Kindly write your advise here. :)


        =====
        iOS Version: %@
        App Version: %@
        =====
        """
    }
}
