//
//  Trial.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 04/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum Status {
    case inTrial
    case noLicenseKey
    case invalidLicenseKey
    case validLicenseKey
    case error(Error)
}


enum ValidationError: Error {
    case postDataEncodingError
}


struct LicenseInfo {
    static let length = DateComponents(day: 7)

    let firstLaunched: Date
    let licenseKey: String?

    var trialEnd: Date { return Calendar.current.date(byAdding: LicenseInfo.length, to: firstLaunched)! }
    var inTrialPeriod: Bool { return Current.date() <= trialEnd }
}


typealias ResponseHandler = (Data?, URLResponse?, Error?) -> Void
typealias DataTaskHandler = (URLRequest, @escaping ResponseHandler) -> URLSessionDataTask


public struct Gumroad {
    var dataTask: DataTaskHandler = URLSession.shared.dataTask

    func validate(licenseKey: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.gumroad.com/v2/licenses/verify")!)
        request.httpMethod = "POST"
        let body = [
            "product_permalink": "hummingbirdapp",
            "license_key": licenseKey,
        ]

        guard let postData = try? JSONEncoder().encode(body) else {
            completion(.failure(ValidationError.postDataEncodingError))
            return
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData

        self.dataTask(request) { data, urlResponse, error in
            if let error = error {
                completion(.failure(error))
            } else {
                if
                    let urlResponse = urlResponse,
                    let httpResponse = urlResponse as? HTTPURLResponse,
                    httpResponse.statusCode == 200 {
                    completion(.success(true))
                } else {
                    completion(.success(false))
                }
            }
        }.resume()
    }
}


func validate(_ trialData: LicenseInfo, completion: @escaping (Status) -> ()) {
    if let licenseKey = trialData.licenseKey {
        Current.gumroad.validate(licenseKey: licenseKey) { result in
            switch result {
            case .success(let valid):
                completion(valid ? .validLicenseKey: .invalidLicenseKey)
            case .failure(let error):
                completion(.error(error))
            }
        }
    } else {
        if trialData.inTrialPeriod {
            completion(.inTrial)
        } else {
            completion(.noLicenseKey)
        }
    }
}

