//
//  Worker.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "ScreenController.h"

@protocol WorkerManager
-(void)workerDidDisconnect;
@end

@interface Worker : NSObject <GCDAsyncSocketDelegate> {
    dispatch_queue_t dispatchQueue;
    GCDAsyncSocket *socket;
    id <WorkerManager> manager;
    BOOL authenticated;
    NSTimeInterval lastMessage;
    
    BOOL registeredForScreenUpdates;
    
    BOOL sendingRects;
    
    NSMutableData *dirtyScreenRegions;
    RDScreenRes dirtyRegionsResolution;
    CGRect dirtyRect;
}
@property(retain) GCDAsyncSocket *socket;
@property(assign) id <WorkerManager> manager;

-(id)initWithID:(NSInteger)workerID;
-(void)beginConversation;

@end
