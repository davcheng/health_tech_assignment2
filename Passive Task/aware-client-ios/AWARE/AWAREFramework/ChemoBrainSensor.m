//
//  ChemoBrainSensor.m
//  AWARE
//
//  Created by David Cheng on 3/8/17.
//  Copyright © 2017 David and Jill. All rights reserved.
//

#import <HealthKit/HealthKit.h>
#import <Foundation/Foundation.h>
#import "ChemoBrainSensor.h"
#import "ChemoBrainSensor.h"
#import "AppDelegate.h"
#import "EntityChemoBrain.h"
#import "IOSActivityRecognition.h"
#import "AmbientNoise.h"
#import "Screen.h"
#import "notify.h"
#import "AppDelegate.h"
#import "EntityScreen.h"

//#import "AWAREHealthKitWorkout.h"

@implementation ChemoBrainSensor{
    NSTimer * timer;
    HKHealthStore *healthStore;
    
    CMMotionActivityManager *motionActivityManager;
    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
    double defaultInterval;
    IOSActivityRecognitionMode sensingMode;
    CMMotionActivityConfidence confidenceFilter;
    
    
    
    /* stationary,walking,running,automotive,cycling,unknown */
    NSString * ACTIVITY_NAME_STATIONARY;
    NSString * ACTIVITY_NAME_WALKING;
    NSString * ACTIVITY_NAME_RUNNING;
    NSString * ACTIVITY_NAME_AUTOMOTIVE;
    NSString * ACTIVITY_NAME_CYCLING;
    NSString * ACTIVITY_NAME_UNKNOWN;
    NSString * CONFIDENCE;
    NSString * ACTIVITIES;
    NSString * LABEL;
}


// initializer
- (instancetype) initWithAwareStudy:(AWAREStudy *)study
dbType:(AwareDBType)dbType {
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION
                        dbEntityName:NSStringFromClass([EntityChemoBrain class])
                              dbType:dbType];
    
    if (self) {
    }
    return self;
}

// send create table query
- (void) createTable {
    NSString *query = [[NSString alloc] init];
    
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "activity_name text default '',"
    "activity_type text default '',"
    "confidence int default 4,"
    "activities text default ''";

    
    [super createTable:query];
}



// start sensor
- (BOOL) startSensorWithSettings:(NSArray *)settings{
    // Fire -getData: method per 60 sec
    timer = [NSTimer scheduledTimerWithTimeInterval:60.0f
                                             target:self
                                           selector:@selector(getDave:)
                                           userInfo:nil
                                            repeats:YES];
    
    double frequency = [self getSensorSetting:settings withKey:@"frequency_plugin_ios_activity_recognition"];
    if (frequency < defaultInterval) {
        frequency = defaultInterval;
    }
    
    int liveMode = [self getSensorSetting:settings withKey:@"status_plugin_ios_activity_recognition_live"];
    
    return YES;
}


/** step sensor */
- (BOOL) stopSensor {
    [timer invalidate];
    return YES;
}


//////////////////////////////////////////////////
- (void) getData:(id)sender{
    // Get values (unixtime and device_id are required for all AWARE sensor)
    NSNumber * unixtime  = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSString * device_id = [self getDeviceId];
    NSString * value     = @"value";
    
    // Set the values to a dictionary object
    // (NOTE: Please insert the values with the same format on the created table)
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime  forKey:@"timestamp"];
    [dict setObject:device_id forKey:@"device_id"];
    [dict setObject:@"value"  forKey:@"value"];
    
    // Save the dictionary object to a local storage
    [self saveData:dict];
}
@end
