//
//  EntityChemoBrainDataProperties.h
//  AWARE
//
//  Created by David Cheng on 3/12/17.
//  Copyright © 2017 David and Jill NISHIYAMA. All rights reserved.
//

#import "EntityChemoBrain.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityChemoBrain (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *activities;
@property (nullable, nonatomic, retain) NSString *activity_name;
@property (nullable, nonatomic, retain) NSString *activity_type;
@property (nullable, nonatomic, retain) NSNumber *confidence;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

//
@property (nullable, nonatomic, retain) NSNumber *screen_status;

@end

NS_ASSUME_NONNULL_END
