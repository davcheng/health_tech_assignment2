//
//  DeviceUsage.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/14/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "DeviceUsage.h"
#import "notify.h"
#import "AppDelegate.h"
#import "EntityDeviceUsage.h"

NSString* const AWARE_PREFERENCES_STATUS_DEVICE_USAGE = @"status_plugin_device_usage";

@implementation DeviceUsage {
    double lastTime;
    int _notifyTokenForDidChangeLockStatus;
    // int _notifyTokenForDidChangeDisplayStatus;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_DEVICE_USAGE
                        dbEntityName:NSStringFromClass([EntityDeviceUsage class])
                              dbType:dbType];
    if (self) {
        [self setCSVHeader:@[@"timestamp",@"device_id",@"elapsed_device_on",@"elapsed_device_off"]];
    
        [self setTypeAsPlugin];
        
        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_DEVICE_USAGE desc:@"true or false to activate or deactivate accelerometer sensor."];
    }
    return self;
}

- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "elapsed_device_on real default 0,"
    "elapsed_device_off real default 0";
    // "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"[%@] Start Device Usage Sensor", [self getSensorName]);
    lastTime = [[[NSDate alloc] init] timeIntervalSince1970];
    
    [self registerAppforDetectDisplayStatus];
    
    return YES;
}

- (BOOL)stopSensor{
    [self unregisterAppforDetectDisplayStatus];
    return YES;
}

- (void)saveDummyData{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:@0 forKey:@"elapsed_device_on"]; // real
    [dic setObject:@0 forKey:@"elapsed_device_off"]; // real
    [self saveData:dic];
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


- (void) registerAppforDetectDisplayStatus {
//    int notify_token;
    // notify_register_dispatch("com.apple.iokit.hid.displayStatus", &_notifyTokenForDidChangeDisplayStatus,dispatch_get_main_queue(), ^(int token) {
    notify_register_dispatch("com.apple.springboard.lockstate", &_notifyTokenForDidChangeLockStatus,dispatch_get_main_queue(), ^(int token) {
        
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        
        
        int awareScreenState = 0;
        double currentTime = [[NSDate date] timeIntervalSince1970];
        double elapsedTime = currentTime - lastTime;
        lastTime = currentTime;
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        // screen off
        if(state == 0) {
            awareScreenState = 0;
            [dict setObject:@(elapsedTime) forKey:@"elapsed_device_on"]; // real
            [dict setObject:@0 forKey:@"elapsed_device_off"]; // real
            if ([self isDebug]) {
                NSLog(@"screen off");
//                NSString * message = [NSString stringWithFormat:@"Elapsed Time of device ON: %@ [Event at %@]",
//                                      [self unixtime2str:elapsedTime],
//                                      [self nsdate2FormattedTime:[NSDate new]]
//                                      ];
//                [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
            }
        // screen on
        } else {
            awareScreenState = 1;
            [dict setObject:@0 forKey:@"elapsed_device_on"]; // real
            [dict setObject:[NSNumber numberWithDouble:elapsedTime] forKey:@"elapsed_device_off"]; // real
            if([self isDebug]){
                NSLog(@"screen on");
//                NSString * message = [NSString stringWithFormat:@"Elapsed Time of device OFF: %@ [Event at %@]",
//                                      [self unixtime2str:elapsedTime],
//                                      [self nsdate2FormattedTime:[NSDate new]]
//                                      ];
//                [AWAREUtils sendLocalNotificationForMessage:message soundFlag:NO];
            }
        }
        
        [self setLatestValue:[NSString stringWithFormat:@"[%d] %f", awareScreenState, elapsedTime ]];
        [self saveData:dict];
        [self setLatestData:dict];
        
    });
}


- (void) unregisterAppforDetectDisplayStatus {
    //    notify_suspend(_notifyTokenForDidChangeDisplayStatus);
    /*
    uint32_t result = notify_cancel(_notifyTokenForDidChangeDisplayStatus);
    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK ==> %d", result);
    } else {
        NSLog(@"[screen] NO ==> %d", result);
    }
    */
    
    //    notify_suspend(_notifyTokenForDidChangeLockStatus);
    uint32_t result = notify_cancel(_notifyTokenForDidChangeLockStatus);
    
    if (result == NOTIFY_STATUS_OK) {
        NSLog(@"[screen] OK --> %d", result);
    } else {
        NSLog(@"[screen] NO --> %d", result);
    }
}


/////////////////////////////////////////////////////////////

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityDeviceUsage * deviceUsage = (EntityDeviceUsage *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                         inManagedObjectContext:childContext];
    deviceUsage.timestamp = [data objectForKey:@"timestamp"];
    deviceUsage.device_id = [data objectForKey:@"device_id"];
    deviceUsage.elapsed_device_on = [data objectForKey:@"elapsed_device_on"];
    deviceUsage.elapsed_device_off = [data objectForKey:@"elapsed_device_off"];
    
}




/////////////////////////////////////////////////////////////

-(NSString*)unixtime2str:(double)elapsedTime{
    NSString * strElapsedTime = @"";
    if( elapsedTime < 60){
        strElapsedTime = [NSString stringWithFormat:@"%d sec.", (int)elapsedTime];
    }else{ // 1min
        strElapsedTime = [NSString stringWithFormat:@"%d min.", (int)(elapsedTime/60)];
    }
    return strElapsedTime;
}

-(NSString*)nsdate2FormattedTime:(NSDate*)date{
    NSDateFormatter *formatter=[[NSDateFormatter alloc]init];
    // [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    [formatter setDateFormat:@"HH:mm:ss"];
    return [formatter stringFromDate:date];
}


@end
