//
//  TutorialViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    private let viewModel: TutorialViewModel

    init(viewModel: TutorialViewModel = TutorialViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 37) {
                    ForEach(viewModel.steps) { step in
                        TutorialStepView(step: step)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 10)
            }
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
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
