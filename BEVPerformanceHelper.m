//
//  BEVPerformanceHelper.m
//  Freq Peek
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 9/20/13.
//  Distributed under the MIT License -- see LICENSE file for details.
//

#import "BEVPerformanceHelper.h"

NSString * const BEVIgnoredIdentifier = @"BEVIgnoredIdentifier";

NSString * const BEVIdentiferException = @"BEVIdentifierException";
NSString * const BEVInterruptedMeasurementException = @"BEVInterruptedMeasurementException";

@interface BEVPerformanceHelper ()
// Start/stop state
@property (nonatomic, readwrite, strong) NSMutableDictionary *startOnceTokens;
@property (nonatomic, readwrite, strong) NSMutableDictionary *stopOnceTokens;

// Measurement state
@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSString *activeIdentifier;
@property (nonatomic, readwrite, strong) dispatch_semaphore_t measurementSemaphore;

// Results
@property (nonatomic, readwrite, strong) NSMutableDictionary *measurements;
@property (nonatomic, readwrite, strong) dispatch_semaphore_t fileAccessSemaphore;
@property (nonatomic, readwrite) BOOL nslogMeasurement;

// Behaviors
@property (nonatomic, readwrite) BOOL removeResultsExceedingTwoStdDevs;
@property (nonatomic, readwrite) NSInteger minimumResultsForEvaluation;
@property (nonatomic, readwrite) NSInteger numberOfResultsToPersist;
@property (nonatomic, readonly) BOOL useFileStorage;
@end

@implementation BEVPerformanceHelper

#pragma mark Init

+ (BEVPerformanceHelper *)sharedInstance
{
    static BEVPerformanceHelper *singletonInstance;
#if DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [[BEVPerformanceHelper alloc] init];
    });
#endif
    return singletonInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.removeResultsExceedingTwoStdDevs = YES;
        self.minimumResultsForEvaluation = 10;
        self.numberOfResultsToPersist = 200;
        
        self.fileAccessSemaphore = dispatch_semaphore_create(1);
        self.measurementSemaphore = dispatch_semaphore_create(1);
        
        self.startOnceTokens = [[NSMutableDictionary alloc] init];
        self.stopOnceTokens = [[NSMutableDictionary alloc] init];
        
        self.nslogMeasurement = YES;
    }
    return self;
}

// Never called under ARC, but this implementation tracks owned resources
- (void)dealloc
{
//    dispatch_release(self.measurementSemaphore);
//    dispatch_release(self.fileAccessSemaphore);
    self.startOnceTokens = nil;
    self.stopOnceTokens = nil;
    self.startDate = nil;
    self.activeIdentifier = nil;
    self.measurements = nil;
}

#pragma mark Public interface - start and stop

- (void)prepareToMeasureWithIdentifier:(NSString *)identifier
{
    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else if (nil != self.activeIdentifier) {
            [self assertNoAPICallDuringMeasurement];
        } else {
            dispatch_once_t startOnceToken = 0;
            dispatch_once_t stopOnceToken = 0;
            [self.startOnceTokens setObject:[NSNumber numberWithLong:startOnceToken] forKey:identifier];
            [self.stopOnceTokens setObject:[NSNumber numberWithLong:stopOnceToken] forKey:identifier];
            
            // BUG: concat identifier with bundle identifier to avoid collisions between app and framework
        }
    }
}

- (void)discardPreviousResultsForIdentifier:(NSString *)identifier
{
    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else {
            [self beginAccessingFileDataWithIdentifier:identifier addIdentifierIfMissing:NO];
            [self.measurements removeObjectForKey:identifier];
            [self endAccessingFileData];
        }
    }
}

- (void)startWithIdentifier:(NSString *)identifier
{
    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else if (nil != self.activeIdentifier) {
            [self assertNoNestingForIdentifier:identifier];
        } else {
            NSNumber *onceTokenNumber = [self.startOnceTokens objectForKey:identifier];
            if (nil == onceTokenNumber) {
                [self assertUnrecognizedIdentifier:identifier];
            } else {
                dispatch_semaphore_wait(self.measurementSemaphore, DISPATCH_TIME_NOW);
                self.activeIdentifier = identifier;
                dispatch_once_t onceToken = [onceTokenNumber longValue];
                dispatch_once(&onceToken, ^{
                    self.startDate = [NSDate date];
                });
            }
        }
    }
}

- (void)stopWithIdentifier:(NSString *)identifier
{
    NSDate *stopDate = [NSDate date];

    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else if (nil == self.activeIdentifier) {
            [self assertStopCalledBeforeStartForIdentifier:identifier];
        } else if (![identifier isEqualToString:self.activeIdentifier]) {
            [self assertMismatchedIdentifierExpected:self.activeIdentifier actual:identifier];
        } else {
            NSNumber *onceTokenNumber = [self.stopOnceTokens objectForKey:identifier];
            if (nil == onceTokenNumber) [self assertUnrecognizedIdentifier:identifier];
            if (nil != onceTokenNumber) {
                dispatch_once_t onceToken = [onceTokenNumber longValue];
                dispatch_once(&onceToken, ^{
                    NSTimeInterval measurement = [stopDate timeIntervalSinceDate:self.startDate];
                    [self recordMeasurement:measurement forIdentifier:identifier];
                    self.startDate = nil;
                });
            }
        }
        self.activeIdentifier = nil;
        dispatch_semaphore_signal(self.measurementSemaphore);
    }
}

- (void)measureBlock:(void (^)(void))measuredBlock withIdentifier:(NSString *)identifier
{
    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else if (nil != self.activeIdentifier) {
            [self assertNoNestingForIdentifier:identifier];
        } else {
            [self prepareToMeasureWithIdentifier:identifier];

            dispatch_semaphore_wait(self.measurementSemaphore, DISPATCH_TIME_NOW);
            self.activeIdentifier = identifier;

            self.startDate = [NSDate date];
            measuredBlock();
            NSDate *stopDate = [NSDate date];
            
            NSTimeInterval measurement = [stopDate timeIntervalSinceDate:self.startDate];
            [self recordMeasurement:measurement forIdentifier:identifier];
            self.startDate = nil;
            self.activeIdentifier = nil;
            dispatch_semaphore_signal(self.measurementSemaphore);
        }
    }
}

- (NSTimeInterval)getNewestTimedMeasurementForIdentifier:(NSString *)identifier
{
    NSTimeInterval result = CGFLOAT_MIN;
    if (![identifier isEqualToString:BEVIgnoredIdentifier]) {
        if (nil == identifier) {
            [self assertNilIdentifierNotAllowed];
        } else if (nil != self.activeIdentifier) {
            [self assertNoAPICallDuringMeasurement];
        } else {
            [self beginAccessingFileDataWithIdentifier:identifier addIdentifierIfMissing:NO];
            NSArray *results = [self.measurements objectForKey:identifier];
            if (nil == results) {
                [self endAccessingFileData];
                [self assertNoMeasurementsForIdentifier:identifier];
            } else {
                if (results.count > 0) {
                    result = [(NSNumber *)[results lastObject] doubleValue];
                }
                [self endAccessingFileData];
            }
        }
    }
    return result;
}

- (void)recordUntimedMeasurement:(CGFloat)measurement forIdentifier:(NSString *)identifier
{
    // BUG: not implemented
}

#pragma mark File management

- (BOOL)useFileStorage
{
    return YES;
}

- (void)beginAccessingFileDataWithIdentifier:(NSString *)identifier addIdentifierIfMissing:(BOOL)addIfMissing
{
    dispatch_semaphore_wait(self.fileAccessSemaphore, DISPATCH_TIME_FOREVER);
    
    NSString *plistPath = [self pathToPlist];
    if ([self useFileStorage] && [[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        self.measurements = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    } else if (nil == self.measurements) {
        self.measurements = [[NSMutableDictionary alloc] init];
    }
    if (![[self.measurements allKeys] containsObject:identifier]) {
        if (addIfMissing) {
            [self.measurements setObject:[NSArray array] forKey:identifier];
        }
    }
}

- (void)endAccessingFileData
{
    if ([self useFileStorage]) {
        [self.measurements writeToFile:[self pathToPlist] atomically:YES];
        // BUG: nil out self.measurements only if there are no active identifiers
        self.measurements = nil;
    }
    
    dispatch_semaphore_signal(self.fileAccessSemaphore);
}

- (NSString *)pathToPlist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [libraryDirectory stringByAppendingPathComponent:@"BEVPerformanceMeasurements.plist"];
    return plistPath;
}

- (void)recordMeasurement:(NSTimeInterval)measurement forIdentifier:(NSString *)identifier
{
    NSNumber *onceTokenNumber = [self.stopOnceTokens objectForKey:identifier];
    if (nil == onceTokenNumber) [self assertUnrecognizedIdentifier:identifier];
    if (nil != onceTokenNumber) {
        dispatch_once_t onceToken = [onceTokenNumber longValue];
        dispatch_once(&onceToken, ^{
            [self beginAccessingFileDataWithIdentifier:identifier addIdentifierIfMissing:YES];
            
            NSMutableArray *results = [[self.measurements objectForKey:identifier] mutableCopy];
            if (nil == results) {
                [self assertNoMeasurementsForIdentifier:identifier];
            } else {
                [results addObject:[NSNumber numberWithDouble:measurement]];
                NSInteger count = results.count;
                if (count > self.numberOfResultsToPersist) {
                    NSInteger difference = count - self.numberOfResultsToPersist;
                    for (NSInteger i = 0; i < difference; i++) {
                        [results removeObjectAtIndex:i];
                    }
                }
                [self.measurements setObject:results forKey:identifier];
                [self analyzeMeasurementsForIdentifier:identifier];
            }
            
            [self endAccessingFileData];
        });
    }
}

#pragma mark Analysis

- (void)analyzeMeasurementsForIdentifier:(NSString *)identifier
{
    NSMutableArray *results = [self.measurements objectForKey:identifier];
    if (nil == results) {
        [self assertNoMeasurementsForIdentifier:identifier];
    } else {
        NSTimeInterval fastest = CGFLOAT_MAX;
        NSTimeInterval slowest = CGFLOAT_MIN;
        NSTimeInterval sum = 0.0f;
        
        for (NSNumber *num in results) {
            NSTimeInterval result = num.doubleValue;
            sum += result;
            if (result < fastest) {
                fastest = result;
            }
            if (result > slowest) {
                slowest = result;
            }
        }
        
        NSTimeInterval average = sum / (double)results.count;
        
        NSTimeInterval thisMeasurement = [(NSNumber *)[results lastObject] doubleValue];
        CGFloat stdDev = 0.0f;
        
        if (results.count >= self.minimumResultsForEvaluation) {
            if (thisMeasurement == fastest) {
                NSLog(@"New fastest measurement");
            }
            if (thisMeasurement == slowest) {
                NSLog(@"New slowest measurement"); // Breakpoint recommended here
            }

            stdDev = [self standardDeviationForMeasurementsWithIdentifier:identifier];
            if (stdDev > average) {
                NSLog(@"Standard deviation exceeds average");
            }

            BOOL rejectNewestMeasurement = NO;
            if ([self result:thisMeasurement exceedsCount:3 standardDeviation:stdDev fromAverage:average]) {
                NSLog(@"Measurement exceeds three standard deviations"); // Breakpoint recommended here
                rejectNewestMeasurement = YES;
            } else if ([self result:thisMeasurement exceedsCount:2 standardDeviation:stdDev fromAverage:average]) {
                NSLog(@"Measurement exceeds two standard deviations"); // Breakpoint recommended here
                rejectNewestMeasurement = YES;
            } else if ([self result:thisMeasurement exceedsCount:1 standardDeviation:stdDev fromAverage:average]) {
                NSLog(@"Measurement exceeds one standard deviation"); // Breakpoint recommended here
            }
            
            if (rejectNewestMeasurement) {
                NSLog(@"This measurement has been rejected");
                [results removeLastObject];
                [self.measurements setObject:results forKey:identifier];
            }
        }
        
        if (self.nslogMeasurement) {
            NSTimeInterval newestResult = [(NSNumber *)[results lastObject] doubleValue];
            NSLog(@"[%@] fastest:%.3f average:%.3f slowest:%.3f newest:%.3f stddev:%.3f", identifier, fastest, average, slowest, newestResult, stdDev);
        }
    }
}

- (BOOL)result:(CGFloat)result exceedsCount:(NSInteger)count standardDeviation:(CGFloat)stdDev fromAverage:(CGFloat)average
{
    CGFloat lowThreshold = average - (stdDev * (CGFloat)count);
    CGFloat highThreshold = average + (stdDev * (CGFloat)count);
    if ((lowThreshold > result) || (highThreshold < result)) {
        return YES;
    }
    return NO;
}
    
- (CGFloat)standardDeviationForMeasurementsWithIdentifier:(NSString *)identifier
{
    NSArray *results = [self.measurements objectForKey:identifier];
    if (nil == results) [self assertNoMeasurementsForIdentifier:identifier];
    
    CGFloat sum = 0.0f;
    for (NSNumber *result in results) {
        sum += result.doubleValue;
    }

    CGFloat count = (CGFloat)results.count;
    CGFloat average = sum / count;

    CGFloat squaredSum = 0.0f; // variable needs better name
    for (NSNumber *result in results) {
        squaredSum += pow(result.doubleValue - average, 2);
    }
    
    CGFloat stdDeviation = sqrt(squaredSum / count);
    
    return stdDeviation;
}

#pragma mark Asserts

- (void)assertNoMeasurementsForIdentifier:(NSString *)identifier
{
    [NSException raise:BEVIdentiferException format:@"Error: identifier \"%@\" not found in measurements data", identifier];
}

- (void)assertNilIdentifierNotAllowed
{
    [NSException raise:BEVIdentiferException format:@"A nil identifier is not allowed"];
}

- (void)assertUnrecognizedIdentifier:(NSString *)identifier
{
    [NSException raise:BEVIdentiferException format:@"Identifier %@ not recognized (you must call prepareToMeasureWithIdentifier: first)", identifier];
}

- (void)assertMismatchedIdentifierExpected:(NSString *)expected actual:(NSString *)actual
{
    [NSException raise:BEVIdentiferException format:@"Expected identifier \"%@\" but got identifier \"%@\" -- methods called out of order or nested. Nested start/stop is not allowed.", expected, actual];
}

- (void)assertStopCalledBeforeStartForIdentifier:(NSString *)identifier
{
    [NSException raise:BEVIdentiferException format:@"You must call startWithIdentifier: before stopWithIdentifier: -- for identifier \"%@\"", identifier];
}

- (void)assertNoNestingForIdentifier:(NSString *)identifier
{
    [NSException raise:BEVIdentiferException format:@"You may not nest calls to startWithIdentifier: . Identifier \"%@\" passed while identifier \"%@\" is still active", identifier, self.activeIdentifier];
}

- (void)assertNoAPICallDuringMeasurement
{
    [NSException raise:BEVInterruptedMeasurementException format:@"You may not call other BEVPerformanceHelper methods during an active measurement"];
}

@end

// TODO: detect hardware change between uses of identifiers?
// TODO: detect significant time elapsed since last measurement?
// TODO: add anticipated ranges per identifier? "result was faster/slower than anticipated range"
// TODO: timed and untimed measurements: same code path internally
// TODO: add API versioning to the dictionary so old results are discarded or even better, partitioned
// TODO: add optional exceptions for slowest/exceeds 2 std dev/exceeds 3 std dev/rejected
