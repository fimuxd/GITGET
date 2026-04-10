//
//  AboutViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/17/21.
//

import SwiftUI
import StoreKit
import MessageUI
import SafariServices

enum SettingMenu {
    case rating
    case sendMail
    case gitHub
    case linkedin
    case instagram
}

struct AboutView: View {
    @State private var selectedMenu: SettingMenu?
    @State private var isShowingMailComposer = false
    @State private var safariURL: URL?

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

            VStack(spacing: 30) {
                actionButton(title: "Rate GitGet".localized, menu: .rating)
                actionButton(title: "Support".localized, menu: .sendMail)

                HStack(spacing: 20) {
                    socialButton(imageName: "logo_github", menu: .gitHub)
                    socialButton(imageName: "logo_linkedin", menu: .linkedin)
                    socialButton(imageName: "logo_instagram", menu: .instagram)
                }
                .padding(.top, 6)
            }
            .padding(.top, 50)

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
    }

    private func actionButton(title: String, menu: SettingMenu) -> some View {
        Button(title) {
            selectedMenu = menu
        }
        .font(.system(size: 18, weight: .bold, design: .monospaced))
        .foregroundColor(Color("title"))
        .buttonStyle(.plain)
    }

    private func socialButton(imageName: String, menu: SettingMenu) -> some View {
        Button {
            selectedMenu = menu
        } label: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }

    private func handle(_ menu: SettingMenu) {
        switch menu {
        case .rating:
            requestReview()
        case .sendMail:
            if MFMailComposeViewController.canSendMail() {
                isShowingMailComposer = true
            }
        case .gitHub:
            open(SystemConstants.SNS.github, fallback: SystemConstants.SNS.github)
        case .linkedin:
            open(SystemConstants.SNS.linkedinDirect, fallback: SystemConstants.SNS.linkedin)
        case .instagram:
            open(SystemConstants.SNS.instagramDirect, fallback: SystemConstants.SNS.instagram)
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
}

private struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        let userSystemVersion = UIDevice.current.systemVersion
        let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([SystemConstants.Email.emailAddress])
        controller.setSubject(SystemConstants.Email.subject)
        controller.setMessageBody(
            String(format: SystemConstants.Email.body, userSystemVersion, userAppVersion),
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
