//
//  Barometer.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Barometer.h"
#import "AppDelegate.h"
#import "EntityBarometer.h"

NSString* const AWARE_PREFERENCES_STATUS_BAROMETER    = @"status_barometer";
NSString* const AWARE_PREFERENCES_FREQUENCY_BAROMETER = @"frequency_barometer";

@implementation Barometer{
    CMAltimeter* altitude;
    double sensingInterval;
    int dbWriteInterval;
    double timestamp;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_BAROMETER
                        dbEntityName:NSStringFromClass([EntityBarometer class])
                              dbType:dbType];
    if (self) {
        sensingInterval = 0.2f;
        dbWriteInterval = 30;
        [self setCSVHeader:@[@"timestamp",@"device_id", @"double_values_0",@"accuracy",@"label"]];
        [self addDefaultSettingWithBool:@NO       key:AWARE_PREFERENCES_STATUS_BAROMETER        desc:@"e.g., True or False"];
        [self addDefaultSettingWithNumber:@200000 key:AWARE_PREFERENCES_FREQUENCY_BAROMETER     desc:@"Non-deterministic frequency in microseconds (dependent of the hardware sensor capabilities and resources). You can also use a SensorManager sensor delay constant."];
        // [self addDefaultSettingWithNumber:@0      key:AWARE_PREFERENCES_FREQUENCY_HZ_BAROMETER  desc:@""];
    }
    return self;
}


- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"double_values_0" type:TCQTypeReal default:@"0"];
    [tcqMaker addColumn:@"accuracy" type:TCQTypeInteger default:@"0"];
    [tcqMaker addColumn:@"label" type:TCQTypeText default:@"''"];
    NSString * query = [tcqMaker getDefaudltTableCreateQuery];
    [super createTable:query];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    // Get a sensing frequency
    double frequency = [self getSensorSetting:settings withKey:@"frequency_barometer"];
    if(frequency != -1){
        // NOTE: The frequency value is a microsecond
        frequency = frequency/1000000;
    }else{
        // default value = 200000(microseconds) = 0.2(second)
        frequency = sensingInterval;
    }
    
    // Set a buffer size for reducing file access
    int buffer = (int)(dbWriteInterval/frequency);
    return [self startSensorWithInterval:frequency bufferSize:buffer];
}

- (BOOL) startSensor{
    return [self startSensorWithInterval:sensingInterval];
}

- (BOOL) startSensorWithInterval:(double)interval{
    return [self startSensorWithInterval:interval bufferSize:[self getBufferSize]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer{
    return [self startSensorWithInterval:interval bufferSize:buffer fetchLimit:[self getFetchLimit]];
}

- (BOOL) startSensorWithInterval:(double)interval bufferSize:(int)buffer fetchLimit:(int)fetchLimit{
    
    [super startSensor];
    
    [self setFetchLimit:fetchLimit];
    
    [self setBufferSize:buffer];
    
    timestamp = [[NSDate new] timeIntervalSince1970];
    
    // Set and start a sensor
    NSLog(@"[%@] Start Barometer Sensor", [self getSensorName]);
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        NSLog(@"This device doesen't support CMAltimeter.");
    } else {
        altitude = [[CMAltimeter alloc] init];
        
        [altitude startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue]
                                          withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
                                              
                                              double currentTimestamp = [[NSDate new] timeIntervalSince1970];
                                              
                                              if( (currentTimestamp - timestamp) > interval ){
                                                  
                                                 timestamp = currentTimestamp;
                                                  
                                                 double pressureDouble = [altitudeData.pressure doubleValue];

                                                 NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
                                                 NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                 [dict setObject:unixtime forKey:@"timestamp"];
                                                 [dict setObject:[self getDeviceId] forKey:@"device_id"];
                                                 [dict setObject:@(pressureDouble*10.0f) forKey:@"double_values_0"];
                                                 [dict setObject:@3 forKey:@"accuracy"];
                                                 [dict setObject:@"" forKey:@"label"];
                                                 [self setLatestValue:[NSString stringWithFormat:@"%f", pressureDouble*10.0f]];
  
                                                  if([self getDBType] == AwareDBTypeCoreData) {
                                                      [self saveData:dict];
                                                  }else if([self getDBType] == AwareDBTypeTextFile){
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self saveData:dict];
                                                      });
                                                  }
                                                  
                                                  
                                                  [self setLatestValue:[NSString stringWithFormat:@"%f", (pressureDouble * 10.0f)]];
                                                  
                                                  [self setLatestData:dict];
                                                  
                                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:dict
                                                                                                       forKey:EXTRA_DATA];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_BAROMETER
                                                                                                      object:nil
                                                                                                    userInfo:userInfo];
                                              }
                                          }];
    }
    return YES;
}

- (void)insertNewEntityWithData:(NSDictionary *)data managedObjectContext:(NSManagedObjectContext *)childContext entityName:(NSString *)entity{
    EntityBarometer * pressureData = (EntityBarometer *)[NSEntityDescription
                                                         insertNewObjectForEntityForName:entity
                                                         inManagedObjectContext:childContext];
    
    pressureData.device_id = [data objectForKey:@"device_id"];
    pressureData.timestamp = [data objectForKey:@"timestamp"];
    pressureData.double_values_0 = [data objectForKey:@"double_values_0"];
    pressureData.accuracy = @0;
    pressureData.label = @"";

}


-(void)saveDummyData{
    [self setBufferSize:0];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@1024 forKey:@"double_values_0"];
    [dict setObject:@0 forKey:@"accuracy"];
    [dict setObject:@"dummy" forKey:@"label"];
    [self saveData:dict];
}

- (BOOL)stopSensor{
    // Stop a altitude sensor
    [altitude stopRelativeAltitudeUpdates];
    altitude = nil;
    
    [super stopSensor];
    
    return YES;
}

- (BOOL) setInterval:(double)interval{
    sensingInterval = interval;
    return YES;
}

- (double) getInterval{
    return sensingInterval;
}


@end
