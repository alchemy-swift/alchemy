//
//  File.swift
//  
//
//  Created by Josh Wright on 8/22/23.
//

import Foundation

extension Logger {
    static var stdout: Logger {
        Logger(label: "Alchemy", factory: { StreamLogHandler.standardOutput(label: $0) })
    }

    static var stderr: Logger {
        Logger(label: "Alchemy", factory: { StreamLogHandler.standardError(label: $0) })
    }
}
