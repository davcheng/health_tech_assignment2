//
//  AWARESensors.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/10/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Sensors
#import "Accelerometer.h"
#import "AmbientLight.h"
#import "Barometer.h"
#import "Battery.h"
#import "BatteryCharge.h"
#import "BatteryDischarge.h"
#import "Bluetooth.h"
#import "Calls.h"
#import "Gravity.h"
#import "Debug.h"
#import "Gravity.h"
#import "Gyroscope.h"
#import "IBeacon.h"
#import "LinearAccelerometer.h"
#import "Locations.h"
#import "VisitLocations.h"
#import "Magnetometer.h"
#import "Network.h"
#import "Orientation.h"
#import "Pedometer.h"
#import "Processor.h"
#import "Proximity.h"
#import "Rotation.h"
#import "Screen.h"
#import "Timezone.h"
#import "Wifi.h"
#import "ESM.h"

/// Plugins
#import "ChemoBrainSensor.h"

#import "ActivityRecognition.h"
#import "AmbientNoise.h"
#import "BalacnedCampusESMScheduler.h"
#import "BLEHeartRate.h"
#import "DeviceUsage.h"
#import "FusedLocations.h"
#import "GoogleCalPull.h"
#import "GoogleCalPush.h"
#import "AWAREHealthKit.h"
#import "Labels.h"
#import "Memory.h"
#import "MSBand.h"
#import "MSBandHR.h"
#import "MSBandUV.h"
#import "MSBandGSR.h"
#import "MSBandCalorie.h"
#import "MSBandDistance.h"
#import "MSBandSkinTemp.h"
#import "MSBandPedometer.h"
#import "NTPTime.h"
#import "Observer.h"
#import "OpenWeather.h"
#import "PushNotification.h"
#import "SensorTag.h"
#import "IOSESM.h"
#import "Meal.h"
#import "IOSActivityRecognition.h"
#import "Contacts.h"
#import "Fitbit.h"

@interface AWARESensors : NSObject

@end
