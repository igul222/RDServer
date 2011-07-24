//
//  ScreenArray.m
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScreenArray.h"

@implementation ScreenArray

#pragma mark - Init and dealloc

- (id)initWithSize:(RDScreenRes)size {
    self = [super init];
    if (self) {
        @synchronized(self) {
            resolution = size;
            size_t arrLength = sizeof(BOOL) * resolution.width * resolution.height;
            array = malloc(arrLength);
            memset(array,  (int)YES, arrLength);
        }
    }
    return self;
}

-(void)dealloc {
    @synchronized(self) {
        free(array);
    }
    [super dealloc];
}

@end
