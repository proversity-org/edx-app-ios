//
//  XBlockApiClient.swift
//  edX
//
//  Created by José Antonio González on 2018/06/14.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

public class XBlockApiClient {
    public typealias Environment = OEXConfigProvider & OEXSessionProvider
    
    private let environment : Environment
    private let session = URLSession(configuration: .default)
    private let authorizationHeaders : [String : String]
    public let baseUrl : URL
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.authorizationHeaders = environment.session.authorizationHeaders
        self.baseUrl = environment.config.apiHostURL()!
    }
    
    public func makeSettingsRequest<T: XBlockApiRequestData>(_ requestData: T, completionHandler: @escaping (String) -> Void) -> Void {
        print("makeSettingsRequest")
        let url = URL(string: self.buildXBlockSettingsEndpoint(for: requestData))
        var request : URLRequest = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        for (key, value) in self.authorizationHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            print("finish request")
            if let err = error {
                print(err.localizedDescription)
            } else if data != nil {
                let res = response as? HTTPURLResponse
                print(res?.statusCode as Any)
                do {
                    if let dataJSON = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                        let blocks = dataJSON["blocks"] as? [String: AnyObject]
                        print(blocks![requestData.blockId] as Any)
                        let block = blocks![requestData.blockId] as? [String: AnyObject]
                        print(block!["student_view_data"] as Any)
                        completionHandler("yes")
                    } else {
                        print("error on json")
                        completionHandler("error on json")
                    }
                } catch {
                    completionHandler("error on json")
                }
            }
        })

        dataTask.resume()
    }
    
    private func buildXBlockSettingsEndpoint<T: XBlockApiRequestData>(for request: T) -> String {
        let queryParams = "?username=\(request.username)&student_view_data=\(request.studentViewData)"
        return "\(baseUrl)/\(request.resourceName)/\(request.blockId)/\(queryParams)"
    }
    
    private func buildXBlockUserDataEndpoint<T: XBlockApiRequestData>(for request: T) -> URL {
        return URL(string: "\(baseUrl)/\(request.resourceName)")!
    }
}
