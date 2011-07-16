//
//  AppUtils.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TELNET_MODE YES
#define PORT 51617
#define PASSWORD @"hello"
#define TIMEOUT 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface AppUtils : NSObject

+(void)log:(NSString *)message;
+(void)handleError:(NSError *)error context:(NSString *)context;
+(void)handleNonFatalError:(NSError *)error context:(NSString *)context;

@end
