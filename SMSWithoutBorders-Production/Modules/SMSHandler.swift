//
//  SMSHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 02/08/2024.
//

import Foundation
import MessageUI

class SMSHandler {
    static public func sendSMS(message: String, receipient: String, messageComposeDelegate: MFMessageComposeViewControllerDelegate) {
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = messageComposeDelegate
        messageVC.recipients = [receipient]
        messageVC.body = message
        
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        
        if MFMessageComposeViewController.canSendText() {
            vc?.present(messageVC, animated: true)
        }
        else {
            print("User hasn't setup Messages.app")
        }
    }
}
