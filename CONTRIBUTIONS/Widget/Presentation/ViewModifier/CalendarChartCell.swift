//
//  CalendarChartCell.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct CalendarChartCell: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .stroke(Color.clear, lineWidth: 1.0)
            )
            .cornerRadius(1.0)
    }
}
