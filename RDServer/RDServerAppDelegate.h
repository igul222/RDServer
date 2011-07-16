//
//  RDServerAppDelegate.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"
#import "Worker.h"

@class ServerSocketDelegate;
@interface RDServerAppDelegate : NSObject <NSApplicationDelegate, GCDAsyncSocketDelegate, WorkerManager> {
    NSWindow *window;
    
    dispatch_queue_t socketQueue;
    GCDAsyncSocket *listenSocket;
    
    int workersCreated;
    int workersDestroyed;
}

@property (assign) IBOutlet NSWindow *window;

@end
