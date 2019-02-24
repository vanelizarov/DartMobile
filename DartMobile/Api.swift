//
//  Api.swift
//  DartMobile
//
//  Created by vanya elizarov on 23/02/2019.
//  Copyright © 2019 vanya elizarov. All rights reserved.
//

import Alamofire

struct CompileResult {
    // js code
    let js: String
}

class Api {
    static func compile(source: String, completion: @escaping (CompileResult?) -> Void) {
        guard let endpoint = URL(string: "https://dart-services.appspot.com/api/dartservices/v1/compile") else {
            completion(nil)
            return
        }
        
        Alamofire.request(endpoint,
                          method: .post,
                          parameters: ["source": source],
                          encoding: JSONEncoding.default)
            .validate()
            .responseJSON { (res) in
                guard res.result.isSuccess else {
                    print("Error while fetching compilation result: \(String(describing: res.result.error?.localizedDescription))")
                    completion(nil)
                    return
                }
                
                guard let value = res.result.value as? [String: String], let result = value["result"] else {
                    print("Malformed data received from compilation endpoint")
                    completion(nil)
                    return
                }
                
                let compResult = CompileResult(js: result)
                completion(compResult)
        }
    }
}













