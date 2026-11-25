//
//  File.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/11/2026.
//

import Foundation
import SwiftUI
import MessageUI

struct MessageComposer: UIViewControllerRepresentable {
    let body: String
    var recipients: [String] = []
    var onFinish: (MessageComposeResult) -> Void = { _ in }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.body = body
        vc.recipients = recipients
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposer
        init(_ parent: MessageComposer) { self.parent = parent }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) {
                self.parent.onFinish(result)
            }
        }
    }
}
