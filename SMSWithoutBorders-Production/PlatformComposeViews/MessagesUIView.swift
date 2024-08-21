//
//  MessageUIViewController.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 21/08/2024.
//

import Foundation
import SwiftUI
import MessageUI

protocol MessagesViewDelegate {
    func messageCompletion(result: MessageComposeResult)
}

class MessageViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    var delegate: MessagesViewDelegate?
    var recipients: [String]?
    var body: String?

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        self.delegate?.messageCompletion(result: result)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    public func displayMessageInterface() {
        let messageVC = MFMessageComposeViewController()
//        messageVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
//            barButtonSystemItem: .done, target: self, action: Selector(("dismiss")))
//        messageVC.navigationBar.isHidden = true
        
        messageVC.messageComposeDelegate = self
        messageVC.recipients = recipients
        messageVC.body = body
        
        if MFMessageComposeViewController.canSendText() {
            self.present(messageVC, animated: true, completion: nil)
        }
        else {
            print("User hasn't setup Messages.app")
        }
    }

}

struct MessagesUIView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    var recipients: [String]
    @Binding var body: String
    var completion: ((_ result: MessageComposeResult) -> Void)


    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MessageViewController {
        let controller = MessageViewController()
        controller.delegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MessageViewController, context: Context) {
        uiViewController.recipients = recipients
        uiViewController.displayMessageInterface()
    }
    
    
    class Coordinator: NSObject, UINavigationControllerDelegate, MessagesViewDelegate {
        var parent: MessagesUIView
        
        init(_ controller: MessagesUIView) {
            self.parent = controller
        }
        
        // delegate method
        func messageCompletion(result: MessageComposeResult) {
            self.parent.presentationMode.wrappedValue.dismiss()
            self.parent.completion(result)
        }
    }
}
