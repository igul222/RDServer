//
//  ScreenArray.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "ScreenController.h"

typedef struct _RectArray {
    CGRect *array;
    CGRectCount count;
    unsigned int capacity;
    unsigned int retainCount;
} RectArray;

@interface ScreenArray : NSObject {
    RDScreenRes resolution; 
    BOOL *array;
}

-(id)initWithSize:(RDScreenRes)size;
-(void)fillRects:(CGRect *)rectArray count:(CGRectCount)count;
-(RectArray)dirtyRects;

-(NSUInteger)height;

@end
