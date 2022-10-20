//
//  SMSSharing.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/20/22.
//

import Foundation
import MessageUI

class SMSSharing : UIViewController, MFMessageComposeViewControllerDelegate {
    public func sendSMS(message: String, receipient: String) {
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        messageVC.recipients = [receipient]
        messageVC.body = message
        
        if MFMessageComposeViewController.canSendText() {
            self.present(messageVC, animated: true, completion: nil)
        }
        else {
            print("User hasn't setup Messages.app")
        }
    }

    // this function will be called after the user presses the cancel button or sends the text
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

