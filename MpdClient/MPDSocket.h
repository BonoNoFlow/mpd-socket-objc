//
//  MPDSocket.h
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <Cocoa/Cocoa.h>
#import "Command.h"


#define BUFFER_SIZE 1024

#define END_RESPONSE    @"OK"
#define ERROR_RESPONSE  @"ACK"
#define NEW_LINE        '\n'

@interface MPDSocket : NSObject {
    
    int sock;
}

@property NSString *host;
@property NSString *port;
@property NSString *version;
@property NSString *ack;

- (NSString *)version;

- (id)initWithHost:(NSString *)nHost port:(NSString *)nPort;



- (NSArray *)sendCommand:(Command *)command error:(NSError **)error;

@end
