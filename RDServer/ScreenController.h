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
} RDScreenRes;
extern RDScreenRes ScreenResMake(NSUInteger width, NSUInteger height);
extern BOOL ScreenResEqual(RDScreenRes res1, RDScreenRes res2);

@interface ScreenController : NSObject

+(RDScreenRes)currentResolution;
+(void)changeResolution;
+(void)restoreOriginalResolution;

@end
