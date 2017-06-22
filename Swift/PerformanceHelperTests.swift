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
    
    func testPrepareNoThrow() {
        let uuid: String = NSUUID().uuidString
        XCTAssertNoThrow(ph.prepareToMeasure(identifier: uuid))
    }
    
    func testStartWithoutPrepare() {
        let uuid: String = NSUUID().uuidString
        XCTAssertThrowsError(ph.startMeasuring(identifier: uuid))
    }
    
    func testStopWithoutPrepare() {
        let uuid: String = NSUUID().uuidString
        XCTAssertThrowsError(ph.stopMeasuring(identifier: uuid))
    }
    
    func testStopWithoutStart() {
        let uuid: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: uuid)
        XCTAssertThrowsError(ph.stopMeasuring(identifier: uuid))
    }
    
    func testPrepareDuringMeasurement() {
        let firstUUID: String = NSUUID().uuidString
        let secondUUID: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: firstUUID)
        ph.startMeasuring(identifier: firstUUID)
        XCTAssertThrowsError(ph.prepareToMeasure(identifier: secondUUID))
        ph.stopMeasuring(identifier: firstUUID)
    }
    
    func testPrepareOrderDoesNotMatter() {
        let firstUUID: String = NSUUID().uuidString
        let secondUUID: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: secondUUID)
        ph.prepareToMeasure(identifier: firstUUID)
        XCTAssertNoThrow(ph.startMeasuring(identifier: firstUUID))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: firstUUID))
        XCTAssertNoThrow(ph.startMeasuring(identifier: secondUUID))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: secondUUID))
    }
    
    func testStopTwice() {
        let uuid: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: uuid)
        ph.startMeasuring(identifier: uuid)
        ph.stopMeasuring(identifier: uuid)
        XCTAssertThrowsError(ph.stopMeasuring(identifier: uuid))
    }
    
    func testStartStopMismatchedIdentifiers() {
        let firstUUID: String = NSUUID().uuidString
        let secondUUID: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: firstUUID)
        ph.startMeasuring(identifier: firstUUID)
        XCTAssertThrowsError(ph.stopMeasuring(identifier: secondUUID))
        ph.stopMeasuring(identifier: firstUUID)
    }
    
    func testStartNesting() {
        let firstUUID: String = NSUUID().uuidString
        let secondUUID: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: firstUUID)
        ph.prepareToMeasure(identifier: secondUUID)
        ph.startMeasuring(identifier: firstUUID)
        XCTAssertThrowsError(ph.startMeasuring(identifier: secondUUID))
        ph.stopMeasuring(identifier: firstUUID)
    }
    
    func testNilIdentifier() {
        let uuid: String? = nil
        XCTAssertThrowsError(ph.prepareToMeasure(identifier: uuid!))
        XCTAssertThrowsError(ph.discardPreviousResults(identifier: uuid!))
        XCTAssertThrowsError(ph.startMeasuring(identifier: uuid!))
        XCTAssertThrowsError(ph.stopMeasuring(identifier: uuid!))
        XCTAssertThrowsError(ph.getNewestTimedMeasurement(identifier: uuid!))
    }
    
    func testNormalUsage() {
        let uuid: String = NSUUID().uuidString
        XCTAssertNoThrow(ph.prepareToMeasure(identifier: uuid))
        XCTAssertNoThrow(ph.startMeasuring(identifier: uuid))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: uuid))
        XCTAssertNoThrow(ph.discardPreviousResults(identifier: uuid))
    }
    
    func testGetNewestResult() {
        let uuid: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: uuid)
        ph.startMeasuring(identifier: uuid)
        ph.stopMeasuring(identifier: uuid)
        var ti: TimeInterval?
        XCTAssertNoThrow(ti = ph.getNewestTimedMeasurement(identifier: uuid))
        XCTAssertTrue(ti! >= Double(0.0), "Result is " + String(ti!));
    }
    
    func testGetResultDuringMeasurement() {
        let uuid: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: uuid)
        ph.startMeasuring(identifier: uuid)
        var ti: TimeInterval?
        XCTAssertThrowsError(ti = ph.getNewestTimedMeasurement(identifier: uuid));
        ph.stopMeasuring(identifier: uuid)
    }

    func testGetResultBeforePrepare() {
        let uuid: String = NSUUID().uuidString
        XCTAssertThrowsError(ph.getNewestTimedMeasurement(identifier: uuid));
    }
    
    func testGetResultBeforeFirstMeasurement() {
        let uuid: String = NSUUID().uuidString
        ph.prepareToMeasure(identifier: uuid)
        var ti: TimeInterval?
        XCTAssertThrowsError(ti = ph.getNewestTimedMeasurement(identifier: uuid));
    }
    
    func testPublicInterfaceWithIgnoredIdentifier() {
        XCTAssertNoThrow(ph.prepareToMeasure(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.startMeasuring(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.getNewestTimedMeasurement(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.discardPreviousResults(identifier: PHConstants.ignoredIdentifier))
    }
    
    func testOuterNestedIgnoredIdentifier() {
        let uuid: String = NSUUID().uuidString
        
        ph.prepareToMeasure(identifier: PHConstants.ignoredIdentifier)
        ph.prepareToMeasure(identifier: uuid)
        
        ph.startMeasuring(identifier: PHConstants.ignoredIdentifier)
        XCTAssertNoThrow(ph.startMeasuring(identifier: uuid))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: uuid))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: PHConstants.ignoredIdentifier))
    }
    
    func testInnerNestedIgnoredIdentifier() {
        let uuid: String = NSUUID().uuidString
        
        ph.prepareToMeasure(identifier: uuid)
        ph.prepareToMeasure(identifier: PHConstants.ignoredIdentifier)
        
        ph.startMeasuring(identifier: uuid)
        XCTAssertNoThrow(ph.startMeasuring(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: PHConstants.ignoredIdentifier))
        XCTAssertNoThrow(ph.stopMeasuring(identifier: uuid))
    }
    
    func testPrepareDuringIgnoredStartStop() {
        let uuid: String = NSUUID().uuidString
        
        ph.prepareToMeasure(identifier: PHConstants.ignoredIdentifier)
        ph.startMeasuring(identifier: PHConstants.ignoredIdentifier)
        XCTAssertNoThrow(ph.prepareToMeasure(identifier: uuid));
        ph.stopMeasuring(identifier: PHConstants.ignoredIdentifier)
    }
    
    func testDuplicatePrepare() {
        let uuid: String = NSUUID().uuidString
        
        ph.prepareToMeasure(identifier: uuid)
        ph.startMeasuring(identifier: uuid)
        ph.stopMeasuring(identifier: uuid)
        XCTAssertThrowsError(ph.prepareToMeasure(identifier: uuid));
    }
    
    func testPerformClosure() {
        let uuid: String = NSUUID().uuidString
        
        var closurePerformed: Bool = false
        ph.prepareToMeasure(identifier: uuid)
        ph.measureClosure(closure: {
            closurePerformed = true
        }, withIdentifier: uuid)
        XCTAssertTrue(closurePerformed)
    }
    
    func testMeasureClosure() {
        let uuid: String = NSUUID().uuidString

        let delay: UInt32 = 2
        XCTAssertNoThrow(ph.measureClosure(closure: {
            sleep(delay)
        }, withIdentifier: uuid))
        let result: TimeInterval = ph.getNewestTimedMeasurement(identifier: uuid)
        XCTAssertTrue(result >= Double(delay));
    }

}

/*
 
 - (void)testMeasureBlock
 {
 NSString *identifier = [self uuid];
 
 unsigned int delay = 2;
 XCTAssertNoThrow([self.ph measureWithIdentifier:identifier block:^(void) {
 sleep(delay);
 }], @"");
 
 NSTimeInterval result = [self.ph getNewestTimedMeasurementForIdentifier:identifier];
 XCTAssertTrue(result >= (NSTimeInterval)delay, @"");
 }
 
 - (void)testMeasureBlockNilIdentifier
 {
 XCTAssertThrows([self.ph measureWithIdentifier:nil block:^(void) {
 NSLog(@"This log should not happen");
 }], @"");
 }
 
 - (void)testMeasureBlockWithNesting
 {
 NSString *identifier = [self uuid];
 NSString *blockIdentifier = [self uuid];
 [self.ph prepareToMeasureWithIdentifier:identifier];
 [self.ph startWithIdentifier:identifier];
 XCTAssertThrows([self.ph measureWithIdentifier:blockIdentifier block:^{
 NSLog(@"This log should not happen");
 }], @"");
 [self.ph stopWithIdentifier:identifier];
 }
 
 - (void)testRecordUntimedMeasurement
 {
 NSString *identifier = [self uuid];
 CGFloat expectedMeasurement = 0.35f;
 XCTAssertNoThrow([self.ph recordUntimedMeasurement:expectedMeasurement forIdentifier:identifier], @"");
 CGFloat actualMeasurement = [self.ph getNewestUntimedMeasurementForIdentifier:identifier];
 XCTAssertEqual(expectedMeasurement, actualMeasurement, @"");
 }
 
 - (void)testRecordUntimedMeasurementWhileMeasurementActive
 {
 NSString *id1 = [self uuid];
 NSString *id2 = [self uuid];
 [self.ph prepareToMeasureWithIdentifier:id1];
 [self.ph startWithIdentifier:id1];
 XCTAssertThrows([self.ph recordUntimedMeasurement:0.162f forIdentifier:id2], @"");
 [self.ph stopWithIdentifier:id1];
 }
 
 - (void)testRecordUntimedMeasurementNilIdentifier
 {
 XCTAssertThrows([self.ph recordUntimedMeasurement:0.2f forIdentifier:nil], @"");
 }
 
 - (void)testGetNewestUntimed
 {
 NSString *identifier = [self uuid];
 CGFloat expectedResult = 0.44f;
 [self.ph recordUntimedMeasurement:expectedResult forIdentifier:identifier];
 CGFloat actualResult = CGFLOAT_MIN;
 XCTAssertNoThrow(actualResult = [self.ph getNewestUntimedMeasurementForIdentifier:identifier], @"");
 XCTAssertEqual(expectedResult, actualResult, @"");
 }
 
 - (void)testGetNewestUntimedNilIdentifier
 {
 XCTAssertThrows([self.ph getNewestUntimedMeasurementForIdentifier:nil], @"");
 }
 
 - (void)testGetNewestUntimedDuringMeasurement
 {
 NSString *id1 = [self uuid];
 NSString *id2 = [self uuid];
 [self.ph prepareToMeasureWithIdentifier:id1];
 [self.ph startWithIdentifier:id1];
 XCTAssertThrows([self.ph getNewestUntimedMeasurementForIdentifier:id2], @"");
 [self.ph stopWithIdentifier:id1];
 }
 
 - (void)testGetNewestUntimedNoResults
 {
 NSString *identifier = [self uuid];
 XCTAssertThrows([self.ph getNewestUntimedMeasurementForIdentifier:identifier], @"");
 }
 
 @end
*/
