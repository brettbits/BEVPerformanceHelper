//
//  PerformanceHelper_UnitTesting.swift
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 2017-06-21.
//  Copyright © 2017 Bits Evolving LLC. Distributed under the MIT License -- see LICENSE file for details.
//

import Foundation

class PerformanceHelper_UnitTesting: PerformanceHelper {

    override init() {
        super.init()
        // Override the file storage Bool in the superclass so unit tests do not persist anything to the filesystem
        useFileStorage = false
    }
}
