BEVPerformanceHelper
====================

Objective-C class for measuring and tracking performance (currently focused on time measurement)

Example usage:

```

BEVPerformanceHelper *ph = [BEVPerformanceHelper sharedInstance];

// Measure the duration of an operation
NSString *someTest = @"someTest";
[ph prepareToMeasureWithIdentifier:someTest];
[ph startWithIdentifier:someTest];
// Your code goes here
// Start and Stop can be called from different classes; just get a reference to [BEVPerformanceHelper sharedInstance]
[ph stopWithIdentifier:someTest];

// Measure the duration of a block
NSString *someBlockTest = @"someBlockTest";
[ph measureWithIdentifier:someBlockTest block^{
    // Your block goes here
}];

NSTimeInterval t1 = [ph getNewestTimedMeasurementForIdentifier:someTest];
NSTimeInterval t2 = [ph getNewestTimedMeasurementForIdentifier:someBlockTest];

// Record an untimed measurement such as configuration information
NSString *recordCount = @"recordCount";
[ph recordUntimedMeasurement:225.0 forIdentifier:recordCount];
CGFloat theCount = [ph getNewestUntimedMeasurementForIdentifier:recordCount];
```

Tested with: OS X 10.9.1; Xcode 5.0.2; iOS SDK 7.0.4

