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

public class MessageViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    var delegate: MessagesViewDelegate?
    var recipients: [String]?
    var body: String?

    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        self.delegate?.messageCompletion(result: result)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public func displayMessageInterface() {
        let messageVC = MFMessageComposeViewController()
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

public struct SMSComposeMessageUIView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    var recipients: [String]
    @Binding var body: String
    var completion: ((_ result: MessageComposeResult) -> Void)


    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> MessageViewController {
        let controller = MessageViewController()
        controller.delegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: MessageViewController, context: Context) {
        uiViewController.recipients = recipients
        uiViewController.displayMessageInterface()
    }
    
    
    public class Coordinator: NSObject, UINavigationControllerDelegate, MessagesViewDelegate {
        var parent: SMSComposeMessageUIView
        
        init(_ controller: SMSComposeMessageUIView) {
            self.parent = controller
        }
        
        // delegate method
        func messageCompletion(result: MessageComposeResult) {
            self.parent.presentationMode.wrappedValue.dismiss()
            self.parent.completion(result)
        }
    }
}
