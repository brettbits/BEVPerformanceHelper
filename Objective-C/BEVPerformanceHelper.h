//
//  BEVPerformanceHelper.h
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 9/20/13.
//  Copyright (c) 2014 Bits Evolving LLC. Distributed under the MIT License -- see LICENSE file for details.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

// Nesting measurements is not supported. However, you have the option of using BEVIgnoredIdentifier to temporarily disable
// a measurement, which allows you to insert nested calls in your code with only one pair of start/stop calls enabled.
// Create NSString constants for your identifiers, and for identifiers you want disabled, set them equal to BEVIgnoredIdentifier.
// This makes enabling or disabling a particular measurement a one-line change.

extern NSString * const BEVIgnoredIdentifier;

@interface BEVPerformanceHelper : NSObject

// Singleton accessor. The implementation of this method is wrapped in #if DEBUG

+ (BEVPerformanceHelper *)sharedInstance;

// Identifiers track unique measurement scenarios. Example identifiers are @"AppLaunch" or @"Migrate250Records".
// Named constants with descriptive values are recommended.
// To repeat a scenario within an application session, append a unique string to an identifier, e.g.
//     NSString *identifier = [@"Migrate200Records" stringByAppendingFormat:@"%ld", (unsigned long)count++];
// You are required to call prepareToMeasureWithIdentifier: before calling startWithIdentifier:
// startWithIdentifier: and stopWithIdentifier: will raise exceptions for unrecognized identifiers.
// You can only call startWithIdentifier: and stopWithIdentifier: once per identifier per app session.
// You may not nest calls to startWithIdentifier: -- prepare, start, and stop all must be called in order with the
// same identifier. The identifier passed to stopWithIdentifier: must match the identifier passed to startWithIdentifier:

- (void)prepareToMeasureWithIdentifier:(NSString *)identifier;
- (void)startWithIdentifier:(NSString *)identifier;
- (void)stopWithIdentifier:(NSString *)identifier;

// To measure code within one method or block, use this block-based method. You may not call this with another identifier active.
// Do not pass your identifier to prepareToMeasureWithIdentifier: before using this method.

- (void)measureWithIdentifier:(NSString *)identifier block:(void (^)(void))measuredBlock;

// To record a measurement without recording an operation's duration, use recordUntimedMeasurement:forIdentifier: . You may
// not call this with another identifier active. Do not pass your identifier to prepareToMeasureWithIdentifier: before using
// this method.

- (void)recordUntimedMeasurement:(CGFloat)measurement forIdentifier:(NSString *)identifier;

// You can use your own versioning/date-based logic to determine when to reset the results for an identifier.

- (void)discardPreviousResultsForIdentifier:(NSString *)identifier;

// getNewestTimedMeasurementForIdentifier: and getNewestUntimedMeasurementForIdentifier: differ by return type.

- (NSTimeInterval)getNewestTimedMeasurementForIdentifier:(NSString *)identifier;
- (CGFloat)getNewestUntimedMeasurementForIdentifier:(NSString *)identifier;

@end
