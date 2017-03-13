//
//  SpatialMemoryTask.swift
//  Camelot
//
//  Created by Jill Sue on 3/7/17.
//  Copyright © 2017 Jill Sue. All rights reserved.
//

import Foundation
import ResearchKit

public var SpatialMemoryTask: ORKOrderedTask {
    return ORKOrderedTask.spatialSpanMemoryTask(withIdentifier: "SpatialMemory", intendedUseDescription: "You will observe then recall pattern sequences of increasing length.", initialSpan: 3, minimumSpan: 2, maximumSpan: 15, playSpeed: 1, maximumTests: 5, maximumConsecutiveFailures: 3, customTargetImage: nil, customTargetPluralName: nil, requireReversal: false,options: ORKPredefinedTaskOption.excludeHeartRate)
}
