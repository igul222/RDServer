//
//  ProtocolConstants.h
//  RDServer
//
//  Created by Ishaan Gulrajani on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef RDServer_ProtocolConstants_h
#define RDServer_ProtocolConstants_h

#define TIMEOUT 10.0
#define TELNET_MODE YES
#define PORT 51617
#define PASSWORD @"hello"

#define EOF_STR @"@@@"
#define EOF_DATA [EOF_STR dataUsingEncoding:NSUTF8StringEncoding]

#define NOOP_MSG @"NOOP"
#define AUTHENTICATION_REQUEST_MSG @"AREQ"
#define AUTHENTICATE_MSG @"AUTH"
#define CURRENT_RESOLUTION_MSG @"RESN"
#define SCREEN_MSG @"SCRN"
#define SCREEN_RECT_MSG @"RECT"
#define ALL_RECTS_RECEIVED_MSG @"RCVD"

#endif
