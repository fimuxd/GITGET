//
//  Constants.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import Foundation

struct SystemConstants {
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
    
    struct SNS {
        static let github = "https://github.com/fimuxd"
        static let linkedin = "https://www.linkedin.com/in/parkboyoung/"
        static let linkedinDirect = "linkedin://profile/parkboyoung"
        static let instagram = "https://www.instagram.com/fimuxd/"
        static let instagramDirect = "instagram://user?username=fimuxd"
    }
}
