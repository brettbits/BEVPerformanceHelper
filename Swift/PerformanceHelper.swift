//
//  PerformanceHelper.swift
//
//  Created by Brett Neely <sourcecode@bitsevolving.com> on 2017-06-21.
//  Copyright © 2017 Bits Evolving LLC. Distributed under the MIT License -- see LICENSE file for details.
//

import Foundation

struct PHConstants {
    static let ignoredIdentifier: String = "ignoredIdentifier"
}

enum PerformanceHelperError {
    case identifierError
    case interruptedMeasurement
}

class PerformanceHelper {
    static let sharedInstance = PerformanceHelper()
    
    // Start/Stop state
    var startOnceTokens: Dictionary = [String: Bool]()
    var stopOnceTokens: Dictionary = [String: Bool]()

    // Measurement state
    var startDate: Date?
    var activeIdentifier: String?
    var measurementSemaphore: DispatchSemaphore?
    
    // Results
    var measurements: Dictionary = [String: AnyObject]()
    var fileAccessSemaphore: DispatchSemaphore?
    var printMeasurementLog: Bool
    
    // Behaviors
    var removeResultsExceedingTwoStandardDeviations: Bool
    var minimumResultCountForEvaluation: Int
    var numberOfResultsToPersist: Int
    var useFileStorage: Bool

    init() {
        printMeasurementLog = true
        removeResultsExceedingTwoStandardDeviations = true
        minimumResultCountForEvaluation = 10
        numberOfResultsToPersist = 200
        useFileStorage = true
    }

    func prepareToMeasure(identifier: String) {
        
    }
    
    func startMeasuring(identifier: String) {
        
    }
    
    func stopMeasuring(identifier: String) {
        
    }
    
    func measureClosure(closure: () -> Void, withIdentifier identifier: String) {
        
    }
    
    func recordUntimedMeasurement(measurement: Float, forIdentifier identifier: String) {
        
    }
    
    func discardPreviousResults(identifier: String) {
        
    }
    
    func getNewestTimedMeasurement(identifier: String) -> TimeInterval {
        return 0
    }
    
    func getNewestUntimedMeasurement(identifier: String) -> Float {
        return 0
    }
    
}
