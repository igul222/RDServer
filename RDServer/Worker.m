//
//  Worker.m
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Worker.h"
#import "AppUtils.h"
#import "ProtocolConstants.h"
#import "ImageCompressor.h"
#import "ScreenArray.h"

#define DEFAULT_TAG 0

#define PIXEL_LOC(x,y) ((x)+(dirtyRegionsResolution.width*(y)))

#define MESSAGE_CODE_TO_END_RANGE(l) (NSMakeRange(4, (l) - (4+[EOF_STR length])))
#define RECT_SIZE(x) ((x).size.width * (x).size.height)
typedef struct _RectArray {
    CGRect *array;
    CGRectCount count;
    unsigned int capacity;
    unsigned int retainCount;
} RectArray;

@interface Worker ()
-(void)sendMessage:(NSString *)message;
-(void)authenticateWithHash:(NSString *)hash;

-(void)registerForScreenUpdates;
-(void)screenRectsUpdated:(CGRect *)rectArray count:(CGRectCount)count;
-(RectArray)dirtyRects;
-(void)sendScreenUpdate;
@end

static void screenRefreshCallback(CGRectCount count, const CGRect *rectArray, void *userParam) {
    Worker *worker = (Worker *)userParam;
    [worker screenRectsUpdated:(CGRect *)rectArray count:count];
}

static inline void fill_rect(void *data, CGRect rect, unsigned char value, RDScreenRes dirtyRegionsResolution) {
    int ylimit = (int)(rect.origin.y + rect.size.height);
    for(int y = (int)rect.origin.y; y < ylimit; y++) {
        
        int x = (int)rect.origin.x;
        memset(data+PIXEL_LOC(x, y), value, (size_t)rect.size.width);
    }
}

@implementation Worker
@synthesize manager;

#pragma mark - Init and dealloc

-(id)initWithID:(NSInteger)workerID {
    self = [super init];
    if(self) {
        [self retain];
        dispatchQueue = dispatch_queue_create([FORMAT(@"com.lateralcommunications.RDServer-Worker%i",workerID) cStringUsingEncoding:NSUTF8StringEncoding], 0);
    }
    return self;
}

-(void)dealloc {
    if(registeredForScreenUpdates) {
        CGUnregisterScreenRefreshCallback(screenRefreshCallback, self);
        registeredForScreenUpdates = NO;
    }
    
    [dirtyScreenRegions autorelease];
    
    self.socket.delegate = nil;
    self.socket = nil;
    [super dealloc];
}

#pragma mark - Connection events

-(void)beginConversation {
    [self sendMessage:AUTHENTICATION_REQUEST_MSG];
    [self.socket readDataToData:EOF_DATA withTimeout:TIMEOUT tag:DEFAULT_TAG];
}

-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    return (10.0 + lastMessage - [[NSDate date] timeIntervalSince1970]);
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if(err)
        [AppUtils handleNonFatalError:err context:@"socketDidDisconnect:"];
    
    authenticated = NO;
    
    [self.manager workerDidDisconnect];
    [self autorelease];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    lastMessage = [[NSDate date] timeIntervalSince1970];
    
    NSString *dataStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if(TELNET_MODE)
        dataStr = [dataStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *messageCode = [dataStr substringWithRange:NSMakeRange(0, 4)];
    
    
    if([messageCode isEqualToString:NOOP_MSG]) {
        [self sendMessage:NOOP_MSG];
        
    } else if([messageCode isEqualToString:AUTHENTICATE_MSG]) {
        [self authenticateWithHash:[dataStr substringWithRange:MESSAGE_CODE_TO_END_RANGE([dataStr length])]];
    
    } else if(authenticated) {
        if([messageCode isEqualToString:ALL_RECTS_RECEIVED_MSG])
            [self sendScreenUpdate];
    }
    
    [self.socket readDataToData:EOF_DATA withTimeout:TIMEOUT tag:DEFAULT_TAG];
}

#pragma mark - Authentication

-(void)authenticateWithHash:(NSString *)hash {
    
    authenticated = [hash isEqualToString:PASSWORD];
    [AppUtils log:FORMAT(@"Authenticated: %@", (authenticated ? @"YES" : @"NO"))];
    
    if(authenticated) {
        [self registerForScreenUpdates];
        [self sendScreenUpdate];
    }
}

#pragma mark - Sending screen updates

-(void)registerForScreenUpdates {
    if(registeredForScreenUpdates) {
        // no support (yet?) for calling registerForScreenUpdates twice in a row..
        NSError *error = [NSError errorWithDomain:@"registeredForScreenUpdates" code:1 userInfo:nil];
        [AppUtils handleError:error context:@"if(registeredForScreenUpdates) {...}"];
        return;
    }

    // send the current resolution
    RDScreenRes res = [ScreenController currentResolution];
    NSString *dataStr = FORMAT(@"%@%04d%04d%@",CURRENT_RESOLUTION_MSG,res.width,res.height,EOF_STR);
    [socket writeData:[dataStr dataUsingEncoding:NSUTF8StringEncoding] withTimeout:TIMEOUT tag:DEFAULT_TAG];
    
    // initialize the dirtyScreenRegions buffer
    dirtyRegionsResolution = [ScreenController currentResolution];
    NSUInteger length = (sizeof(BOOL) * dirtyRegionsResolution.width * dirtyRegionsResolution.height);
    dirtyScreenRegions = [[NSMutableData alloc] initWithLength:length];
    
    BOOL *bytes = [dirtyScreenRegions mutableBytes];
    for(int i=0;i<length;i++)
        bytes[i] = YES;
    
    dirtyRect = CGRectMake(0, 0, dirtyRegionsResolution.width, dirtyRegionsResolution.height);
    
    // register for screen updates
    CGRegisterScreenRefreshCallback(screenRefreshCallback, self);
    registeredForScreenUpdates = YES;
}

-(void)screenRectsUpdated:(CGRect *)rectArray count:(CGRectCount)count {    
    @synchronized(dirtyScreenRegions) {
        
        BOOL *bytes = [dirtyScreenRegions mutableBytes];

        for(int i=0;i<count;i++) {
            CGRect rect = rectArray[i];
            fill_rect(bytes, rect, YES, dirtyRegionsResolution);
        }
    }

    if(!sendingRects) {
        dispatch_async(dispatchQueue, ^{
            [self sendScreenUpdate];
        });
    }
}

-(RectArray)dirtyRects {    
    RectArray result;
    result.count = 0;
    result.capacity = 5;
    result.array = malloc(sizeof(CGRect)*result.capacity);
        
    @synchronized(dirtyScreenRegions) {
        BOOL *dirtyRegions = [dirtyScreenRegions mutableBytes];

        for(int y = 0; y < dirtyRegionsResolution.height; y++) {
            for(int x = 0; x < dirtyRegionsResolution.width; x++) {
                
                if(dirtyRegions[PIXEL_LOC(x, y)]) {
                    
                    int rectWidth = 0;
                    while(
                          (x+rectWidth < dirtyRegionsResolution.width) && 
                          (dirtyRegions[PIXEL_LOC(x+rectWidth, y)])
                          )
                        rectWidth++;
                    
                    int rectHeight = 0;
                    BOOL stop = NO;
                    while(!stop) {
                        for(int x2 = x; x2 < x + rectWidth; x2++) {

                            if(
                               (y+rectHeight >= dirtyRegionsResolution.height) ||
                               (!dirtyRegions[PIXEL_LOC(x2, y+rectHeight)])
                               ) {
                                stop = YES;
                                break;
                            }
                        }
                        if(!stop)
                            rectHeight++;
                    }
                    
                    CGRect rect = CGRectMake((CGFloat)x, (CGFloat)y, (CGFloat)rectWidth, (CGFloat)rectHeight);
                    fill_rect(dirtyRegions, rect, NO, dirtyRegionsResolution);
                    
                    result.count = result.count + 1;
                    if(result.count > result.capacity) {
                        result.capacity += 5;
                        result.array = realloc(result.array, sizeof(CGRect)*result.capacity);
                    }
                    result.array[result.count - 1] = rect;
                }
            }
        }
    }
    
    if(result.count >= 2) {
        for(int i=0;i<result.count-1;i++) {
            CGRect unionRect = CGRectUnion(result.array[0], result.array[1]);
            
            CGFloat rectSizeRatio = RECT_SIZE(unionRect)/(RECT_SIZE(result.array[0]) + RECT_SIZE(result.array[1]));
            if(rectSizeRatio >= 1.5) {
                result.array[0] = CGRectZero;
                result.array[1] = unionRect;
            }
        }
    }
    
    return result;
}


-(void)sendScreenUpdate {
    __block RectArray rects = [self dirtyRects];
    if(rects.count == 0) {
        sendingRects = NO;
        free(rects.array);
        return;
    } else {
        sendingRects = YES;
    }
    
    int realRectsCount = 0;
    for(int i=0;i<rects.count;i++)
        if(!CGRectEqualToRect(rects.array[i],CGRectZero))
            realRectsCount++;
    
    NSData *data = [FORMAT(@"%@%i%@", SCREEN_MSG,realRectsCount,EOF_STR) dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:TIMEOUT tag:0];
    
    rects.retainCount = rects.count;
    dispatch_apply(rects.count, dispatch_queue_create("cake", 0), ^(size_t i) {
        CGRect rect = rects.array[i];

        if(CGRectEqualToRect(rect, CGRectZero)) {
            rects.retainCount--;
            if(rects.retainCount == 0) {
                free(rects.array);
            }
            return;
        }
        
        CGImageRef screenshot = CGDisplayCreateImageForRect(kCGDirectMainDisplay, rect); 
        NSData *screenshotData;
        if(!screenshot) {
            screenshotData = [NSData data];
        } else {
            screenshotData = compressImage(screenshot);
            CGImageRelease(screenshot);
        }
        
        NSMutableData *data = [NSMutableData dataWithCapacity:[screenshotData length]+[SCREEN_RECT_MSG length]+8]; // 8 = len(%04d) + len(%04d)
        [data appendData:[FORMAT(@"%@%04d%04d", SCREEN_RECT_MSG, (int)rect.origin.x, (int)(dirtyRegionsResolution.height-rect.origin.y-rect.size.height)) dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:screenshotData];
        [data appendData:EOF_DATA];
        
        [self.socket writeData:data withTimeout:TIMEOUT tag:DEFAULT_TAG];
    
        rects.retainCount--;
        if(rects.retainCount == 0) {
            free(rects.array);
        }
    });
}

#pragma mark - Miscellaneous

// send a control message over the line
-(void)sendMessage:(NSString *)message {
    NSString *messageStr = FORMAT(@"%@%@", message,EOF_STR);
    NSData *messageData = [messageStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.socket writeData:messageData withTimeout:TIMEOUT tag:DEFAULT_TAG];
}


// Custom property methods for socket because we need to do some stuff on assignment.

-(GCDAsyncSocket *)socket {
    GCDAsyncSocket *result;
    @synchronized(self) {
        result = [socket retain];
    }
    return [result autorelease];
}

-(void)setSocket:(GCDAsyncSocket *)newSocket {
    @synchronized(self) {
        if (socket != newSocket) {
            [socket release];
            socket = [newSocket retain];
            
            socket.delegate = self;
            socket.delegateQueue = dispatchQueue;
        }
    }
}


@end
