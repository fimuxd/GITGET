//
//  String.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/16/21.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedStringWithFormat(_ argument: CVarArg) -> String {
        return .localizedStringWithFormat(self.localized, argument)
    }
}
