//
//  AboutConstants.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import Foundation

struct AboutConstants {
    struct Email {
        static let emailAddress = "support@example.com"
        static let subject = "[Example App] Feedback"
        static let body = "Thanks for your feedback!\nKindly write your advise here. :)".localized
            + """

        =====
        iOS Version: %@
        App Version: %@
        =====
        """
    }
    
    struct SNS {
        static let github = "https://example.com/profile"
        static let linkedin = "https://example.com/network"
        static let linkedinDirect = "https://example.com/network"
        static let instagram = "https://example.com/gallery"
        static let instagramDirect = "https://example.com/gallery"
    }
}
