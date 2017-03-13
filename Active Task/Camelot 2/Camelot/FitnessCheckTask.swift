//
//  FitnessCheckTask.swift
//  Camelot
//
//  Created by Jill Sue on 3/8/17.
//  Copyright © 2017 Jill Sue. All rights reserved.
//

import Foundation
import ResearchKit

public var FitnessCheckTask: ORKOrderedTask {
    return ORKOrderedTask.fitnessCheck(withIdentifier: "FitnessCheck", intendedUseDescription: "Please follow the instructions for the two quick fitness tasks.", walkDuration: 5*60, restDuration: 2*60, options: ORKPredefinedTaskOption.excludeHeartRate)
}

