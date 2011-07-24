//
//  ScreenArray.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "ScreenController.h"

@interface ScreenArray : NSObject {
    RDScreenRes resolution; 
    BOOL *array;
}

-(id)initWithSize:(RDScreenRes)size;

@end
