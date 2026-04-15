//
//  WidgetSetupGuideView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import SwiftUI

struct WidgetSetupGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let viewModel: WidgetSetupGuideStepProvider

    private var contentWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .greatestFiniteMagnitude
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 0 : 42
    }

    init(viewModel: WidgetSetupGuideStepProvider = WidgetSetupGuideStepProvider()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 37) {
                    widgetSetupGuideIntroCard
                        .frame(maxWidth: contentWidth, alignment: .leading)

                    ForEach(viewModel.steps) { step in
                        WidgetSetupGuideStepView(step: step)
                            .frame(maxWidth: contentWidth, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 10)
            }
            .accessibilityIdentifier("widgetSetupGuide.scrollView")
            .background(Color("modal_background"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("title"))
                    }
                    .accessibilityIdentifier("widgetSetupGuide.closeButton")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("widgetSetupGuide.root")
    }

    private var widgetSetupGuideIntroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare teams in the app")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(Color("title"))

            Text("GitGet helps you group saved accounts into teams, compare contribution activity, and scan insight cards in the Friends tab.")
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(Color("title"))

            Text("The steps below are only for widget setup. The widget contract stays GitHub-only today, even though the in-app team view can track more than one provider.")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(Color("title"))
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("widgetSetupGuide.introCard")
    }
}
