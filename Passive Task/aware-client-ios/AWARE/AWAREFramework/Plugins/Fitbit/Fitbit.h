//
//  Fitbit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Fitbit : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
+ (void) setFitbitAccessToken:(NSString *)accessToken;
+ (void) setFitbitRefreshToken:(NSString *)refreshToken;
+ (void) setFitbitUserId:(NSString *)userId;
+ (void) setFibitTokenType:(NSString *)tokenType;
+ (NSString *) getFitbitAccessToken;
+ (NSString *) getFitbitRefreshToken;
+ (NSString *) getFitbitUserId;
+ (NSString *) getFitbitTokenType;
- (void) refreshToken;

@end
