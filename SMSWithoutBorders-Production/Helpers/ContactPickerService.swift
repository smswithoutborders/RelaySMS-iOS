//
//  ContactPickerService.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 03/04/2025.
//

import Combine
import Contacts
import ContactsUI

import SwiftUI


class ContactPickerService {
    
    @Published var delegate = ContactPickerServiceDelegate()
   
    func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = delegate
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(contactPicker, animated: true, completion: nil)
    }
}


class ContactPickerServiceDelegate: NSObject, ObservableObject, CNContactPickerDelegate {
    var pickedNumber: String?
    @Published var internationPhoneNumber: String?
    @Published var localPhoneNumber: String?
    @Published var phoneCode: String?
    @Published var rawValue: String?
    @Published var name: String?
    @Published var contact: RelayContact?

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        // Clear the pickedNumber initially
        self.pickedNumber = nil

        // Check if the contact has selected phone numbers
        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
            handlePhoneNumber(phoneNumber)
            
            self.name = contact.givenName + " " + contact.familyName
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        
        // Get the name
        let contact: CNContact = contactProperty.contact
            self.name = contact.givenName + " " + contact.familyName
        
        if contactProperty.key == CNContactPhoneNumbersKey,
           let phoneNumber = contactProperty.value as? CNPhoneNumber {

            let phoneNumberString = phoneNumber.stringValue
            // Now phoneNumberString contains the phone number
            print("Phone Number: \(phoneNumberString)")

            // You can now use phoneNumberString as needed
            handlePhoneNumber(phoneNumberString)
        }
    }

    private func handlePhoneNumber(_ phoneNumber: String) {
        let localNumber = phoneNumber.starts(with: "+") ? phoneNumber.split(separator: " ").dropFirst().joined(separator: " ") : phoneNumber
        let cleanedNumber = localNumber.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "") // This should remove these characters '(' , ')' , '-' , and ' '
        let phoneCode: String = phoneNumber.starts(with: "+") ? String(phoneNumber.split(separator: " ").first ?? "") : ""

        DispatchQueue.main.async {
            self.phoneCode = phoneCode
            self.localPhoneNumber = cleanedNumber
            self.internationPhoneNumber = phoneCode.isEmpty ? nil : "\(phoneCode)\(cleanedNumber)"
            self.rawValue = phoneNumber
            
            self.contact = RelayContact(
                phoneCode: self.phoneCode ?? "",
                localPhoneNumber: self.localPhoneNumber ?? "",
                internationalPhoneNumber: self.internationPhoneNumber ?? "",
                rawValue: self.rawValue ?? "",
                name: self.name ?? ""
            )

            print("international Phone Number: \(self.internationPhoneNumber ?? "N/A") ")
            print("Local Phone Number: \(self.localPhoneNumber ?? "N/A") ")
            print("phoneCode: \(self.phoneCode ?? "N/A") ")
            print("rawValue: \(self.rawValue ?? "N/A") ")
            print("name: \(self.name ?? "N/A")")
        }
    }
    
    

}


struct RelayContact {
    var phoneCode: String = ""
    var localPhoneNumber: String = ""
    var internationalPhoneNumber: String = ""
    var rawValue: String = ""
    var name: String = ""
}



