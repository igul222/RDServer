//
//  ScreenController.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _ScreenRes {
    NSUInteger width;
    NSUInteger height;
} ScreenRes;
extern ScreenRes ScreenResMake(NSUInteger width, NSUInteger height);
extern BOOL ScreenResEqual(ScreenRes res1, ScreenRes res2);

@interface ScreenController : NSObject

+(ScreenRes)currentResolution;
+(void)changeResolution;
+(void)restoreOriginalResolution;

@end
