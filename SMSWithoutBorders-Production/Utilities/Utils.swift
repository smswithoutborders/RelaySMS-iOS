//
//  Helpers.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 28/06/2024.
//

import Foundation
extension Data {
    func base64URLEncodedString() -> String {
        // Get the standard base64 encoded string
        var base64String = self.base64EncodedString()
        
        // Replace characters according to Base64 URL encoding specifications
        base64String = base64String
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
        // Remove padding characters ("=")
        base64String = base64String.trimmingCharacters(in: CharacterSet(charactersIn: "="))
        
        return base64String
    }
}


extension URL {
    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}


func generate32RandomBytes() -> Data? {
    var bytes = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)
    
    guard status == errSecSuccess else {
        return nil
    }
    
    return Data(bytes)
}

func chunkByFours(_ input: String) -> [String] {
    var groups: [String] = []
    var currentIndex = input.startIndex
    let chunkSize = 4
    
    while currentIndex < input.endIndex {
        let nextIndex = input.index(currentIndex, offsetBy: chunkSize, limitedBy: input.endIndex) ?? input.endIndex
        let chunk = String(input[currentIndex..<nextIndex])
        groups.append(chunk)
        currentIndex = nextIndex
    }
    
    return groups
}
