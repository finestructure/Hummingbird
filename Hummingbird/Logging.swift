//
//  Logging.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 14/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import os


enum LogLevel: String {
    case `default`
    case debug
    case info
    case error
    case fault
}


private func log(_ level: LogLevel = .default, _ message: StaticString, _ args: CVarArg...) {
    if #available(OSX 10.14, *) {
        let type: OSLogType
        switch level {
            case .default: type = .default
            case .debug: type = .debug
            case .info: type = .info
            case .error: type = .error
            case .fault: type = .fault
        }
        os_log(type, message, args)
    }
}


func log(_ level: LogLevel = .default, _ message: String) {
    if _isDebugAssertConfiguration() {
        // just use `print` logging for now, it's easier to read in the Xcode console
        log(.debug, "\(level.rawValue): \(message)")
        //    } else {
        //        log(level, "%@", message)
    }
}
