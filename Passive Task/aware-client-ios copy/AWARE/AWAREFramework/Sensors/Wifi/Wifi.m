//
//  Wifi.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Wifi.h"
#import "AppDelegate.h"
#import "EntityWifi.h"
#import "AWAREKeys.h"
#import <ifaddrs.h>
#import <net/if.h>
#import <SystemConfiguration/CaptiveNetwork.h>

NSString* const AWARE_PREFERENCES_STATUS_WIFI = @"status_wifi";
NSString* const AWARE_PREFERENCES_FREQUENCY_WIFI = @"frequency_wifi";

@implementation Wifi{
    NSTimer * sensingTimer;
    double defaultInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_WIFI
                        dbEntityName:NSStringFromClass([EntityWifi class])
                              dbType:dbType];
    if (self) {
        defaultInterval = 60.0f; // 60sec. = 1min.
        [self setCSVHeader:@[@"timestamp",@"device_id",@"bssid",@"ssid",@"security",@"frequency",@"rssi",@"label"]];
    
        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_WIFI desc:@"true or false to activate or deactivate sensor."];
        [self addDefaultSettingWithNumber:@60 key:AWARE_PREFERENCES_FREQUENCY_WIFI desc:@"how often to scan for devices, in seconds (default = 60 seconds)."];
    }
    return self;
}


- (void) createTable {
    // Send a create table query
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "bssid text default '',"
    "ssid text default '',"
    "security text default '',"
    "frequency integer default 0,"
    "rssi integer default 0,"
    "label text default ''";
    //"UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // Get a sensing frequency
    double frequency = [self getSensorSetting:settings withKey:@"frequency_wifi"];
    if(frequency != -1){
        NSLog(@"Wi-Fi sensing requency is %f ", frequency);
    }else{
        frequency = defaultInterval;
    }
    
    return [self startSensorWithInterval:frequency];
}

- (BOOL)startSensor {
    return [self startSensorWithInterval:defaultInterval];
}

- (BOOL)startSensorWithInterval:(double) interval{
    // Set and start a data upload interval
    NSLog(@"[%@] Start Wifi Sensor", [self getSensorName]);
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(getWifiInfo)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getWifiInfo];
    
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sensing timer
    if (sensingTimer != nil) {
        [sensingTimer invalidate];
        sensingTimer = nil;
    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////


- (void) getWifiInfo {
    
    [self broadcastRequestScan];
    
    [self broadcastScanStarted];
    
    // Get wifi information
    //http://www.heapoverflow.me/question-how-to-get-wifi-ssid-in-ios9-after-captivenetwork-is-depracted-and-calls-for-wif-31555640
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSString *bssid = @"";
        NSString *ssid = @"";
        
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
        if(info[@"SSID"]){
            ssid = info[@"SSID"];
        }
        
        NSMutableString *finalBSSID = [[NSMutableString alloc] init];
        NSArray *arrayOfBssid = [bssid componentsSeparatedByString:@":"];
        for(int i=0; i<arrayOfBssid.count; i++){
            NSString *element = [arrayOfBssid objectAtIndex:i];
            if(element.length == 1){
                [finalBSSID appendString:[NSString stringWithFormat:@"0%@:",element]];
            }else if(element.length == 2){
                [finalBSSID appendString:[NSString stringWithFormat:@"%@:",element]];
            }else{
                //            NSLog(@"error");
            }
        }
        if (finalBSSID.length > 0) {
            //        NSLog(@"%@",finalBSSID);
            [finalBSSID deleteCharactersInRange:NSMakeRange([finalBSSID length]-1, 1)];
        } else{
            //        NSLog(@"error");
        }
        
        [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)",ssid, finalBSSID]];
        
        // Save sensor data to the local database.
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:unixtime forKey:@"timestamp"];
        [dict setObject:[self getDeviceId] forKey:@"device_id"];
        [dict setObject:finalBSSID forKey:@"bssid"]; //text
        [dict setObject:ssid forKey:@"ssid"]; //text
        [dict setObject:@"" forKey:@"security"]; //text
        [dict setObject:@0 forKey:@"frequency"];//int
        [dict setObject:@0 forKey:@"rssi"]; //int
        [dict setObject:@"" forKey:@"label"]; //text

        [self saveData:dict];
        
        [self setLatestData:dict];
        
        [self broadcastDetectedNewDevice];
        
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"%@ (%@)",ssid, finalBSSID] soundFlag:NO];
        }
        
        if(![self isWiFiEnabled]){
            [self saveDebugEventWithText:@"Wifi module is powered off" type:DebugTypeWarn label:@""];
        }
    }
    
    [self broadcastScanEnded];
}


-(void)insertNewEntityWithData:(NSDictionary *)data
          managedObjectContext:(NSManagedObjectContext *)childContext
                    entityName:(NSString *)entity{
    
    EntityWifi* entityWifi = (EntityWifi *)[NSEntityDescription
                                      insertNewObjectForEntityForName:entity
                                      inManagedObjectContext:childContext];
    entityWifi.device_id = [data objectForKey:@"device_id"];
    entityWifi.timestamp = [data objectForKey:@"timestamp"];
    entityWifi.bssid = [data objectForKey:@"bssid"];//finalBSSID;
    entityWifi.ssid = [data objectForKey:@"ssid"];//ssid;
    entityWifi.security = [data objectForKey:@"security"];// @"";
    entityWifi.frequency = [data objectForKey:@"frequency"];//@0;
    entityWifi.rssi = [data objectForKey:@"rssi"]; //@0;
    entityWifi.label = [data objectForKey:@"label"];//@"";
}


- (void)saveDummyData{
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:@"dummy" forKey:@"bssid"]; //text
    [dict setObject:@"dummy" forKey:@"ssid"]; //text
    [dict setObject:@"dummy" forKey:@"security"]; //text
    [dict setObject:@0 forKey:@"frequency"];//int
    [dict setObject:@0 forKey:@"rssi"]; //int
    [dict setObject:@"dummy" forKey:@"label"]; //text
    
    [self saveData:dict];
}

///////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

- (void) broadcastDetectedNewDevice{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_NEW_DEVICE
                                                        object:nil
                                                      userInfo:nil];
}

- (void) broadcastScanStarted{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_SCAN_STARTED
                                                        object:nil
                                                      userInfo:nil];
}

- (void) broadcastScanEnded{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_SCAN_ENDED
                                                        object:nil
                                                      userInfo:nil];
}

- (void) broadcastRequestScan{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_AWARE_WIFI_REQUEST_SCAN
                                                        object:nil
                                                      userInfo:nil];
}


- (BOOL) isWiFiEnabled {
    
    NSCountedSet * cset = [NSCountedSet new];
    
    struct ifaddrs *interfaces;
    
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

- (NSDictionary *) wifiDetails {
    return
    (__bridge NSDictionary *)
    CNCopyCurrentNetworkInfo(
                             CFArrayGetValueAtIndex( CNCopySupportedInterfaces(), 0)
                             );
}


@end
