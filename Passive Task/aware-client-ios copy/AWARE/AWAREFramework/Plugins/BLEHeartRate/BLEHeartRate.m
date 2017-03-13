//
//  BLEHeartRate.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 3/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "BLEHeartRate.h"

#import <dlfcn.h>
#import <mach/port.h>
#import <mach/kern_return.h>

#include <stdio.h>

#import "AppDelegate.h"
#import "EntityBLEHeartRate.h"

NSString* const AWARE_PREFERENCES_STATUS_BLE_HR = @"status_plugin_ble_heartrate";

/** (default = 5) in minutes */
NSString * const AWARE_PREFERENCES_PLUGIN_BLE_HR_INTERVAL_TIME_MIN = @"plugin_ble_heartrate_interval_min";

/** (default = 30) in seconds */
NSString * const AWARE_PREFERENCES_PLUGIN_BLE_HR_ACTIVE_TIME_SEC = @"plugin_ble_heartrate_active_time_sec";

@implementation BLEHeartRate {
    NSString * KEY_HR_TIMESTAMP;
    NSString * KEY_HR_DEVICE_ID;
    NSString * KEY_HR_HEARTRATE;
    NSString * KEY_HR_LOCATION;
    NSString * KEY_HR_MANUFACTURER;
    NSString * KEY_HR_RSSI;
    NSString * KEY_HR_LABEL;
    
    NSArray *services;
    
    NSTimer * timer;
    
    double intervalSec;
    double activeTimeSec;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_BLE_HR
                        dbEntityName:NSStringFromClass([EntityBLEHeartRate class])
                              dbType:dbType];
    if (self) {
        KEY_HR_TIMESTAMP = @"timestamp";
        KEY_HR_DEVICE_ID = @"device_id";
        KEY_HR_HEARTRATE = @"heartrate";
        KEY_HR_LOCATION = @"location";
        KEY_HR_MANUFACTURER = @"manufacturer";
        KEY_HR_RSSI = @"rssi";
        KEY_HR_LABEL = @"label";
        
        intervalSec = 60.0f*5.0f;
        activeTimeSec = 30.0f;
        
        [self setCSVHeader:@[KEY_HR_TIMESTAMP,
                             KEY_HR_DEVICE_ID,
                             KEY_HR_HEARTRATE,
                             KEY_HR_LOCATION,
                             KEY_HR_MANUFACTURER,
                             KEY_HR_RSSI,
                             KEY_HR_LABEL]];
        
        _bodyLocation = @-1;
        _manufacturer = @"";
        _heartRate = 0;
        _deviceRssi = @0;
        
        services = @[
                  [CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID],
                  [CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]
                  ];
        [self setTypeAsPlugin];
        [self addDefaultSettingWithBool:@NO   key:AWARE_PREFERENCES_STATUS_BLE_HR desc:@"true or false to activate or deactivate sensor."];
        [self addDefaultSettingWithNumber:@5  key:AWARE_PREFERENCES_PLUGIN_BLE_HR_INTERVAL_TIME_MIN desc:@"Sensing interval (default = 5) in minutes. NOTE: If you set '0' as a sensing interval, the plugin connects the heart-rate sensor always."];
        [self addDefaultSettingWithNumber:@30 key:AWARE_PREFERENCES_PLUGIN_BLE_HR_ACTIVE_TIME_SEC desc:@"Active time (default = 30) for a duty cycle in seconds. NOTE: If you set '0' as an active time, the plugin connects the heart-rate sensor always."];
   }
    return self;
}

- (void)createTable{
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_HR_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_HR_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ int default 0,", KEY_HR_HEARTRATE]];
    [query appendString:[NSString stringWithFormat:@"%@ int default 0,", KEY_HR_LOCATION]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_HR_MANUFACTURER]];
    [query appendString:[NSString stringWithFormat:@"%@ double default 0,", KEY_HR_RSSI]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',",KEY_HR_LABEL]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}



- (BOOL) startSensor{
    return [self startSensorWithSettings:nil];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    bool always = NO;
    
    if (settings != nil) {
        double tempIntervalMin = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_PLUGIN_BLE_HR_INTERVAL_TIME_MIN];
        if(tempIntervalMin > 0){
            intervalSec = 60.0f * tempIntervalMin;
        }
        
        double tempActiveTimeSec = [self getSensorSetting:settings withKey:AWARE_PREFERENCES_PLUGIN_BLE_HR_ACTIVE_TIME_SEC];
        if(tempActiveTimeSec > 0){
            activeTimeSec = tempActiveTimeSec;
        }
        
        if(tempIntervalMin == 0 || tempActiveTimeSec == 0){
            always = YES;
        }
    }
    
    if(always){
        [self startHeartRateSensor];
    }else{
        timer = [NSTimer scheduledTimerWithTimeInterval:intervalSec
                                                 target:self
                                               selector:@selector(startDutyCycle)
                                               userInfo:nil
                                                repeats:YES];
        [timer fire];
    }
    return YES;
}


- (BOOL)stopSensor{
    // Stop a BLE central manager
    //[_myCentralManager stopScan];
    [self stopHeartRateSensor];
    [timer invalidate];
    timer = nil;
    return YES;
}



/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

- (void) startDutyCycle {
    NSLog(@"[%@] Start a duty cycle...", [self getSensorName]);
    [self startHeartRateSensor];
    [self performSelector:@selector(stopHeartRateSensor) withObject:nil afterDelay:activeTimeSec];
}

- (void) startHeartRateSensor{
    // Start a BLE central manager
    _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void) stopHeartRateSensor{
    // Start a BLE central manager
    NSLog(@"[%@]...Stop a duty cycle", [self getSensorName]);
    if(_myCentralManager != nil){
        [_myCentralManager stopScan];
        _myCentralManager = nil;
    }
}


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////




- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
    if([central state] == CBCentralManagerStatePoweredOff){
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }else if([central state] == CBCentralManagerStatePoweredOn){
        NSLog(@"CoreBluetooth BLE hardware is powered on");
        [central scanForPeripheralsWithServices:services options:nil];
    }else if([central state] == CBCentralManagerStateUnauthorized){
        NSLog(@"CoreBluetooth BLE hardware is unauthorized");
    }else if([central state] == CBCentralManagerStateUnknown){
        NSLog(@"CoreBluetooth BLE hardware is unknown");
    }else if([central state] == CBCentralManagerStateUnsupported){
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}


- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI {
    _peripheralDevice = peripheral;
    _peripheralDevice.delegate = self;
    [_myCentralManager connectPeripheral:_peripheralDevice options:nil];

}



- (void) centralManager:(CBCentralManager *) central
   didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral connected");
    peripheral.delegate = self;
    [peripheral readRSSI];
    [peripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [central scanForPeripheralsWithServices:services options:nil];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    [central scanForPeripheralsWithServices:services options:nil];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discoverd serive %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}



- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]])  {  // 1
        for (CBCharacteristic *aChar in service.characteristics)
        {
            // Request heart rate notifications
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID]]) { // 2
                [self.peripheralDevice setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found heart rate measurement characteristic");
            }
            // Request body sensor location
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID]]) { // 3
                [self.peripheralDevice readValueForCharacteristic:aChar];
                NSLog(@"Found body sensor location characteristic");
            }
        }
    }
    
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]])  { // 4
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
                [self.peripheralDevice readValueForCharacteristic:aChar];
                NSLog(@"Found a device manufacturer name characteristic");
            }
        }
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    _deviceRssi = RSSI;
}

- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    return nil;
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    // Updated value for heart rate measurement received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID]]) { // 1
        // Get the Heart Rate Monitor BPM
        [self getHeartBPMData:characteristic error:error];
    }
    
    // Retrieve the characteristic value for manufacturer name received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {  // 2
        [self getManufacturerName:characteristic];
    }
    
    // Retrieve the characteristic value for the body sensor location received
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID]]) {  // 3
        [self getBodyLocation:characteristic];
    }
}


/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

- (void) getHeartBPMData: (CBCharacteristic *) characteristic error:(NSError *) error {
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];      // 1
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0) {          // 2
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
    } else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));  // 3
    }
    // Display the heart rate value to the UI if no error occurred
    if( (characteristic.value)  || !error ) {   // 4
        self.heartRate = bpm;
    }
    
    if([self isDebug]){
        NSLog(@"%hu", self.heartRate);
    }
    
    [self setLatestValue:[NSString stringWithFormat:@"[%@] %d bps (RSSI:%f)",_manufacturer,_heartRate, _deviceRssi.doubleValue]];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    [dict setObject:unixtime forKey:KEY_HR_TIMESTAMP];
    [dict setObject:[self getDeviceId] forKey:KEY_HR_DEVICE_ID];
    [dict setObject:[NSNumber numberWithInt:_heartRate] forKey:KEY_HR_HEARTRATE]; //varchar
    [dict setObject:_bodyLocation forKey:KEY_HR_LOCATION]; //1=chest, 2=wrist
    [dict setObject:_manufacturer forKey:KEY_HR_MANUFACTURER];
    [dict setObject:_deviceRssi forKey:KEY_HR_RSSI];
    [dict setObject:@"BLE" forKey:KEY_HR_LABEL];
    
    [self saveData:dict];
    [self setLatestData:dict];
    
    return;
}


- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    EntityBLEHeartRate * heartRateEntity = (EntityBLEHeartRate *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                               inManagedObjectContext:childContext];
    heartRateEntity.device_id = [data objectForKey:@"device_id"];
    heartRateEntity.timestamp = [data objectForKey:@"timestamp"];
    heartRateEntity.heartrate = [data objectForKey:@"heartrate"];
    heartRateEntity.location = [data objectForKey:@"location"];
    heartRateEntity.manufacturer = [data objectForKey:@"manufacturer"];
    heartRateEntity.rssi = [data objectForKey:@"rssi"];
    heartRateEntity.label = [data objectForKey:@"label"];

}

- (void) getManufacturerName:(CBCharacteristic *) characteristic {
    NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    self.manufacturer = manufacturerName; //[NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];    // 2
    return;
}


- (void) getBodyLocation:(CBCharacteristic *)characteristic {
    NSData *sensorData = [characteristic value];         // 1
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData ) {
        _bodyLocation = [NSNumber numberWithInt:bodyData[0]];  // 2
//        self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"]; // 3
    } else {  // 4
        _bodyLocation = [NSNumber numberWithInt:-1];
//        self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
    }
    return;
}


/////////////////////////////////////////////////////////////////////

- (void)saveDummyData{
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    [dic setObject:unixtime forKey:KEY_HR_TIMESTAMP];
    [dic setObject:[self getDeviceId] forKey:KEY_HR_DEVICE_ID];
    [dic setObject:[NSNumber numberWithInt:_heartRate] forKey:KEY_HR_HEARTRATE]; //varchar
    [dic setObject:_bodyLocation forKey:KEY_HR_LOCATION]; //1=chest, 2=wrist
    [dic setObject:_manufacturer forKey:KEY_HR_MANUFACTURER];
    [dic setObject:_deviceRssi forKey:KEY_HR_RSSI];
    [dic setObject:@"BLE" forKey:KEY_HR_LABEL];
    
    [self saveData:dic];
}

@end
