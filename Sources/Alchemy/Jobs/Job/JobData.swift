//
//  JobStorage.swift
//  
//
//  Created by Chris Anderson on 1/9/21.
//

import Foundation

struct JobData: Codable {
    public let payload: [UInt8]
    public let retryCount: Int
}
