//
//  File.swift
//  
//
//  Created by Chris Anderson on 5/23/20.
//

import Foundation

public protocol Column {}

extension String: Column {}
extension Raw: Column {}
