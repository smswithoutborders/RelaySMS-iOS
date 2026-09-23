//
//  base64Extractor.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 12/06/2025.
//


import Foundation

private func extractBase64Strings(from text: String, minLength: Int = 20) -> [String] {
    let base64Pattern = #"[A-Za-z0-9+/]{4,}={0,2}"#
    
    guard let regex = try? NSRegularExpression(pattern: base64Pattern) else {
        return []
    }
    
    let range = NSRange(text.startIndex..., in: text)
    let matches = regex.matches(in: text, options:[], range: range)
    
    var validBase64Strings: [String] = []
    
    
    for match in matches {
        guard let matchRange = Range(match.range, in: text) else {continue}
        let candidate = String(text[matchRange])
        
        
        // Check if its a valideBase64
        if isValidBase64(candidate) && candidate.count >= minLength {
            validBase64Strings.append(candidate)
        }
    }
    
    return validBase64Strings
}

private func extractLongestBase64(from text: String, minLength: Int = 20) -> String? {
    let base64Strings = extractBase64Strings(from: text, minLength: minLength)
    return base64Strings.max(by: {$0.count < $1.count})
}

private func isValidBase64(_ string: String) -> Bool {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check basic format requirements
    guard !trimmed.isEmpty, trimmed.count >= 4 else {
        return false
    }
    
    // Check lenth - Base64 should be divisible by 4 (with padding)
    let paddingCount = trimmed.suffix(2).filter({ $0 == "=" }).count
    let withoutPadding = trimmed.count - paddingCount
    
    guard (trimmed.count % 4 == 0) || paddingCount > 0 else {
        return false
    }
    
    // Validate character set
    let base64CharSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
    guard trimmed.unicodeScalars.allSatisfy({ base64CharSet.contains($0) }) else {
        return false
    }
    
    // Validate padding rules
    if paddingCount > 0 {
        //Padding can only be at the end
        let paddingIndex = trimmed.firstIndex(of: "=")
        let remainingCharacters = trimmed[paddingIndex!...]
        guard remainingCharacters.allSatisfy({ $0 == "=" }) else {
            return false
        }
        
        guard paddingCount <= 2 else {
            return false
        }
    }
    
    // Try to decode to verify its valid Base64
    guard Data(base64Encoded: trimmed) != nil else {
        return false
    }
    
    return true
}


func extractEncryptedText(from input: String, minLength: Int = 20) -> String? {
    return extractLongestBase64(from: input, minLength: minLength)
}

func decodeBase64String(from base64String: String) -> String {
    let decodedString = String(
        data: Data(base64Encoded: base64String) ?? Data(), encoding: .utf8)
    
    if let result = decodedString, !result.isEmpty {
        print("Successfully decoded the Base64 string: \(result)")
        return result;
    }
    return "";
}

