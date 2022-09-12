//
//  Synchronization.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/11/22.
//

import Foundation

class Synchronization {
    var callbackFunction: ((Data?, URLResponse?, Error?)->Void);
    
    init(callbackFunction: @escaping ((Data?, URLResponse?, Error?)->Void )) {
        self.callbackFunction = callbackFunction
    }
    
    private func getDataInJson(jsonData: [String : String]) -> String {
        
        var post: String = "";
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData)
            
            post = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
            print(post)
        }
        catch {
            print(error)
        }
        
        return post
    }

    private func jsonHTTPCall(url: String, jsonData: String) -> URLSessionDataTask {
        // let url = "https://developers.smswithoutborders.com:15000"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        request.httpBody = jsonData.data(using: String.Encoding.utf8)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        print(request)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            self.callbackFunction(data, response, error)
        })
        
        return task
    }
    
    
    func publicKeyExchange(gatewayServerUrl: String) -> URLSessionDataTask {
        var publicKey: String = ""
        do {
            publicKey = try generateRSAKeyPair()
        }
        catch {
            print(error)
        }
        
        let data = ["public_key" : publicKey]
        
        let jsonData = getDataInJson(jsonData: data)
        
        let task: URLSessionDataTask = jsonHTTPCall(url: gatewayServerUrl, jsonData: jsonData)
        return task
    }
    
    func passwordVerification(userPassword: String, verificationURL: String) -> URLSessionDataTask {
        let data = ["password" : userPassword]
        let jsonData = getDataInJson(jsonData: data)
        
        let task: URLSessionDataTask = jsonHTTPCall(url: verificationURL, jsonData: jsonData)
        return task
    }
}
