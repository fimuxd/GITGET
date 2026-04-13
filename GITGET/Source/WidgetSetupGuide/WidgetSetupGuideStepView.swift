//
//  WidgetSetupGuideStepView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import SwiftUI

struct WidgetSetupGuideStepView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let step: WidgetSetupGuideStep

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 0 : 42
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(step.title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("title"))

            Text(step.description)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(Color("title"))

            Image(step.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("widgetSetupGuide.step.\(step.id)")
    }
}
