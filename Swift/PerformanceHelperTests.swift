//
//  PerformanceHelperTests.swift
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 2017-06-21.
//  Copyright © 2017 Bits Evolving LLC. Distributed under the MIT License -- see LICENSE file for details.
//

import Foundation

import XCTest

extension PerformanceHelper {
    class func sharedInstanceWithoutFileStorage() -> PerformanceHelper {
        let shared = PerformanceHelper.sharedInstance
        shared.useFileStorage = false
        return shared
    }
}

class PerformanceHelperTests: XCTestCase {
    
    let ph: PerformanceHelper = PerformanceHelper.sharedInstanceWithoutFileStorage()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNotNil() {
        XCTAssertNotNil(ph)
    }
    
}
