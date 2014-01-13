BEVPerformanceHelper
====================

Objective-C class for measuring and tracking performance (currently focused on time measurement)

Example usage:

BEVPerformanceHelper *ph = [BEVPerformanceHelper sharedInstance];
NSString *someTest = @"someTest";
[ph prepareToMeasureWithIdentifier:someTest];
[ph startWithIdentifier:someTest];
// Your code goes here
// Start and Stop can be called from different classes; just get a reference to [BEVPerformanceHelper sharedInstance]
[ph stopWithIdentifier:someTest];

NSString *someBlockTest = @"someBlockTest";
[ph measureBlock^{
    // Your block goes here
} withIdentifier:someBlockTest];

NSTimeInterval t1 = [ph getNewestTimedMeasurementForIdentifier:someTest];
NSTimeInterval t2 = [ph getNewestTimedMeasurementForIdentifier:someBlockTest];
