//
//  NoticeTextStyle.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import SwiftUI

struct NoticeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .regular, design: .monospaced))
            .foregroundColor(Color.level0)
            .unredacted()
    }
}
