//
//  BEVPerformanceHelperTest.m
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 9/30/13.
//  Copyright (c) 2014 Bits Evolving LLC. Distributed under the MIT License -- see LICENSE file for details.
//

#import <XCTest/XCTest.h>

#import "BEVPerformanceHelper_UnitTesting.h"

@interface BEVPerformanceHelperTest : XCTestCase
@property (nonatomic, readwrite, strong) BEVPerformanceHelper *ph;
@end

@implementation BEVPerformanceHelperTest

- (NSString *)uuid
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    return uuidString;
}

- (void)setUp
{
    [super setUp];
    self.ph = [BEVPerformanceHelper_UnitTesting sharedInstance];
}

- (void)testNotNil
{
    XCTAssertNotNil(self.ph, @"");
}

- (void)testPrepareNoThrow
{
    NSString *identifier = [self uuid];
    XCTAssertNoThrow([self.ph prepareToMeasureWithIdentifier:identifier], @"");
}

- (void)testStartWithoutPrepare
{
    NSString *identifier = [self uuid];
    XCTAssertThrows([self.ph startWithIdentifier:identifier], @"");
}

- (void)testStopWithoutPrepareOrStart
{
    NSString *identifier = [self uuid];
    XCTAssertThrows([self.ph stopWithIdentifier:identifier], @"");
}

- (void)testPrepareThrowsDuringMeasurement
{
    NSString *firstIdentifier = [self uuid];
    NSString *secondIdentifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:firstIdentifier];
    [self.ph startWithIdentifier:firstIdentifier];
    XCTAssertThrows([self.ph prepareToMeasureWithIdentifier:secondIdentifier], @"");
    [self.ph stopWithIdentifier:firstIdentifier];
}

- (void)testPrepareOrderDoesNotMatter
{
    NSString *firstIdentifier = [self uuid];
    NSString *secondIdentifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:secondIdentifier];
    [self.ph prepareToMeasureWithIdentifier:firstIdentifier];
    XCTAssertNoThrow([self.ph startWithIdentifier:firstIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:firstIdentifier], @"");
    XCTAssertNoThrow([self.ph startWithIdentifier:secondIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:secondIdentifier], @"");
}

- (void)testStopWithoutStart
{
    NSString *identifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:identifier];
    XCTAssertThrows([self.ph stopWithIdentifier:identifier], @"");
}

- (void)testStopTwiceThrows
{
    NSString *identifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:identifier];
    [self.ph startWithIdentifier:identifier];
    [self.ph stopWithIdentifier:identifier];
    XCTAssertThrows([self.ph stopWithIdentifier:identifier], @"");
}

- (void)testStartStopUnmatchedIdentifiers
{
    NSString *startIdentifier = [self uuid];
    NSString *stopIdentifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:startIdentifier];
    [self.ph prepareToMeasureWithIdentifier:stopIdentifier];
    [self.ph startWithIdentifier:startIdentifier];
    XCTAssertThrows([self.ph stopWithIdentifier:stopIdentifier], @"");
    [self.ph stopWithIdentifier:startIdentifier];
}

- (void)testStartNoNesting
{
    NSString *firstIdentifier = [self uuid];
    NSString *secondIdentifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:firstIdentifier];
    [self.ph prepareToMeasureWithIdentifier:secondIdentifier];
    [self.ph startWithIdentifier:firstIdentifier];
    XCTAssertThrows([self.ph startWithIdentifier:secondIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:firstIdentifier], @"");
}

//- (void)testStartStopStart
//{
//    NSString *identifier = [self uuid];
//    [self.ph prepareToMeasureWithIdentifier:identifier];
//    [self.ph startWithIdentifier:identifier];
//    [self.ph stopWithIdentifier:identifier];
//    XCTAssertThrows([self.ph startWithIdentifier:identifier], @"");
//}

- (void)testNilIdentifierThrows
{
    XCTAssertThrows([self.ph prepareToMeasureWithIdentifier:nil], @"");
    XCTAssertThrows([self.ph discardPreviousResultsForIdentifier:nil], @"");
    XCTAssertThrows([self.ph startWithIdentifier:nil], @"");
    XCTAssertThrows([self.ph stopWithIdentifier:nil], @"");
    XCTAssertThrows([self.ph getNewestTimedMeasurementForIdentifier:nil], @"");
}

- (void)testNormalUsage
{
    NSString *identifier = [self uuid];
    XCTAssertNoThrow([self.ph prepareToMeasureWithIdentifier:identifier], @"");
    XCTAssertNoThrow([self.ph startWithIdentifier:identifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:identifier], @"");
    XCTAssertNoThrow([self.ph discardPreviousResultsForIdentifier:identifier], @"");
}

- (void)testGetNewestResult
{
    NSString *identifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:identifier];
    [self.ph startWithIdentifier:identifier];
    [self.ph stopWithIdentifier:identifier];
    NSTimeInterval ti = CGFLOAT_MIN;
    XCTAssertNoThrow(ti = [self.ph getNewestTimedMeasurementForIdentifier:identifier], @"");
    XCTAssertTrue(ti >= 0.0f, @"Result is %f", ti);
}

- (void)testGetResultThrowsDuringMeasurement
{
    NSString *identifier = [self uuid];
    [self.ph prepareToMeasureWithIdentifier:identifier];
    [self.ph startWithIdentifier:identifier];
    NSTimeInterval ti = CGFLOAT_MIN;
    XCTAssertThrows(ti = [self.ph getNewestTimedMeasurementForIdentifier:identifier], @"");
    [self.ph stopWithIdentifier:identifier];
}

- (void)testGetResultNoMeasurements
{
    NSString *identifier = [self uuid];
    XCTAssertThrows([self.ph getNewestTimedMeasurementForIdentifier:identifier], @"");
}

//- (void)testGetResultNoMeasurementsAfterPrepare
//{
//    NSString *identifier = [self uuid];
//    [self.ph prepareToMeasureWithIdentifier:identifier];
//    NSTimeInterval ti = CGFLOAT_MIN;
//    XCTAssertThrows(ti = [self.ph getNewestTimedMeasurementForIdentifier:identifier], @"");
//}

- (void)testPublicInterfaceWithIgnoredIdentifier
{
    XCTAssertNoThrow([self.ph prepareToMeasureWithIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph startWithIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph getNewestTimedMeasurementForIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph discardPreviousResultsForIdentifier:BEVIgnoredIdentifier], @"");
}

- (void)testOuterLayerWithIgnoredIdentifier
{
    NSString *identifier = [self uuid];
    
    [self.ph prepareToMeasureWithIdentifier:BEVIgnoredIdentifier];
    [self.ph prepareToMeasureWithIdentifier:identifier];
    
    [self.ph startWithIdentifier:BEVIgnoredIdentifier];
    XCTAssertNoThrow([self.ph startWithIdentifier:identifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:identifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:BEVIgnoredIdentifier], @"");
}

- (void)testInnerLayerWithIgnoredIdentifier
{
    NSString *identifier = [self uuid];
    
    [self.ph prepareToMeasureWithIdentifier:identifier];
    [self.ph prepareToMeasureWithIdentifier:BEVIgnoredIdentifier];
    
    [self.ph startWithIdentifier:identifier];
    XCTAssertNoThrow([self.ph startWithIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:BEVIgnoredIdentifier], @"");
    XCTAssertNoThrow([self.ph stopWithIdentifier:identifier], @"");
}

- (void)testPrepareDuringIgnoredStartStop
{
    NSString *identifier = [self uuid];
    
    [self.ph prepareToMeasureWithIdentifier:BEVIgnoredIdentifier];
    [self.ph startWithIdentifier:BEVIgnoredIdentifier];
    XCTAssertNoThrow([self.ph prepareToMeasureWithIdentifier:identifier], @"");
    [self.ph stopWithIdentifier:BEVIgnoredIdentifier];
}

- (void)testPrepareMoreThanOnce
{
    NSString *identifier = [self uuid];
    
    [self.ph prepareToMeasureWithIdentifier:identifier];
    [self.ph startWithIdentifier:identifier];
    [self.ph stopWithIdentifier:identifier];
    XCTAssertThrows([self.ph prepareToMeasureWithIdentifier:identifier], @"");
}

- (void)testMeasureBlock
{
    NSString *identifier = [self uuid];

    NSInteger delay = 2;
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
