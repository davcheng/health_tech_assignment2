//
//  ChemoBrainSensor.h
//  AWARE
//
//  Created by David Cheng on 3/13/17.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <CoreMotion/CoreMotion.h>

typedef enum: NSInteger {
    ChemoBrainModeLive = 0,
    ChemoBrainModeHistory = 1
} ChemoBrainMode;



@interface ChemoBrainSensor : AWARESensor <AWARESensorDelegate>


- (BOOL) startSensorWithLiveMode:(CMMotionActivityConfidence) filterLevel;
- (BOOL) startSensorWithHistoryMode:(CMMotionActivityConfidence)filterLevel interval:(double) interval;
- (BOOL) startSensorWithConfidenceFilter:(CMMotionActivityConfidence) filterLevel
                                    mode:(ChemoBrainMode)mode
                                interval:(double) interval;

@end
