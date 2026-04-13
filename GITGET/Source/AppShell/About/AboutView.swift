//
//  AboutView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/17/21.
//

import SwiftUI
import StoreKit
import MessageUI
import SafariServices

enum AboutAction {
    case rating
    case sendMail
    case gitHub
    case linkedin
    case instagram
}

private enum UITestPresentedDestination: String, Identifiable {
    case review
    case mail
    case github
    case linkedin
    case instagram

    var id: String { rawValue }

    var title: String {
        switch self {
        case .review: return "Review Prompt"
        case .mail: return "Mail Composer"
        case .github: return "GitHub"
        case .linkedin: return "LinkedIn"
        case .instagram: return "Instagram"
        }
    }
}

struct AboutView: View {
    @State private var selectedMenu: AboutAction?
    @State private var isShowingMailComposer = false
    @State private var safariURL: URL?
    @State private var uiTestDestination: UITestPresentedDestination?

    private let isUITestMode = ProcessInfo.processInfo.environment["GITGET_UI_TEST_MODE"] == "1"

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color("indicator"))
                .frame(width: 50, height: 10)
                .padding(.top, 18)

            Text("About".localized)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color("about_label"))
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text("GitGet is a team contribution companion for comparing saved members, spotting momentum, and checking yearly activity at a glance.")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Color("title"))
                    .multilineTextAlignment(.center)

                Text("The app view supports team-based comparison and insights. Home and lock screen widgets still stay GitHub-only today.")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color("about_label"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 18)

            VStack(spacing: 30) {
                actionButton(title: "Rate GitGet".localized, menu: .rating)
                actionButton(title: "Support & Feedback".localized, menu: .sendMail)

                HStack(spacing: 20) {
                    socialButton(imageName: "logo_github", menu: .gitHub)
                    socialButton(imageName: "logo_linkedin", menu: .linkedin)
                    socialButton(imageName: "logo_instagram", menu: .instagram)
                }
                .padding(.top, 6)
            }
            .padding(.top, 34)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("modal_background"))
        .onChange(of: selectedMenu) { _, menu in
            guard let menu else { return }
            handle(menu)
            selectedMenu = nil
        }
        .sheet(isPresented: $isShowingMailComposer) {
            MailComposeView()
        }
        .sheet(item: $uiTestDestination) { destination in
            UITestDestinationView(destination: destination)
        }
        .sheet(
            isPresented: Binding(
                get: { safariURL != nil },
                set: { isPresented in
                    if !isPresented {
                        safariURL = nil
                    }
                }
            )
        ) {
            if let safariURL {
                SafariView(url: safariURL)
            }
        }
        .accessibilityIdentifier("about.root")
    }

    private func actionButton(title: String, menu: AboutAction) -> some View {
        Button(title) {
            selectedMenu = menu
        }
        .font(.system(size: 18, weight: .bold, design: .monospaced))
        .foregroundColor(Color("title"))
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier(for: menu))
        .accessibilityLabel(isUITestMode ? accessibilityIdentifier(for: menu) : title)
    }

    private func socialButton(imageName: String, menu: AboutAction) -> some View {
        Button {
            selectedMenu = menu
        } label: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier(for: menu))
        .accessibilityLabel(accessibilityIdentifier(for: menu))
    }

    private func handle(_ menu: AboutAction) {
        if isUITestMode {
            switch menu {
            case .rating:
                uiTestDestination = .review
            case .sendMail:
                uiTestDestination = .mail
            case .gitHub:
                uiTestDestination = .github
            case .linkedin:
                uiTestDestination = .linkedin
            case .instagram:
                uiTestDestination = .instagram
            }
            return
        }

        switch menu {
        case .rating:
            requestReview()
        case .sendMail:
            if MFMailComposeViewController.canSendMail() {
                isShowingMailComposer = true
            }
        case .gitHub:
            open(AboutConstants.SNS.github, fallback: AboutConstants.SNS.github)
        case .linkedin:
            open(AboutConstants.SNS.linkedinDirect, fallback: AboutConstants.SNS.linkedin)
        case .instagram:
            open(AboutConstants.SNS.instagramDirect, fallback: AboutConstants.SNS.instagram)
        }
    }

    private func requestReview() {
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            return
        }

        AppStore.requestReview(in: scene)
    }

    private func open(_ directURLString: String, fallback fallbackURLString: String) {
        guard
            let directURL = URL(string: directURLString),
            let fallbackURL = URL(string: fallbackURLString)
        else {
            return
        }

        UIApplication.shared.open(directURL, options: [:]) { success in
            if !success {
                safariURL = fallbackURL
            }
        }
    }

    private func accessibilityIdentifier(for menu: AboutAction) -> String {
        switch menu {
        case .rating:
            return "about.rateButton"
        case .sendMail:
            return "about.supportButton"
        case .gitHub:
            return "about.githubButton"
        case .linkedin:
            return "about.linkedinButton"
        case .instagram:
            return "about.instagramButton"
        }
    }
}

private struct UITestDestinationView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: UITestPresentedDestination

    var body: some View {
        VStack(spacing: 16) {
            Text(destination.title)
                .font(.headline)
            Text("UI Test Stub")
                .font(.subheadline)
            Button("Close") {
                dismiss()
            }
            .accessibilityIdentifier("about.stub.closeButton")
        }
        .padding()
        .accessibilityIdentifier("about.stub.\(destination.rawValue)")
    }
}

private struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        let userSystemVersion = UIDevice.current.systemVersion
        let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([AboutConstants.Email.emailAddress])
        controller.setSubject(AboutConstants.Email.subject)
        controller.setMessageBody(
            String(format: AboutConstants.Email.body, userSystemVersion, userAppVersion),
            isHTML: false
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(named: "button")
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
