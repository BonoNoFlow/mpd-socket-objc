//
//  MPDSocket.h
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Command.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define BUFFER_SIZE 1024

#define END_RESPONSE "OK\n\0"
#define ACK_RESPONSE "ACK\n\0"

@interface MPDSocket : NSObject {
    
    char *host;
    
    int port;
     
    // integer pointer address to the socket.
    int sock;
    
    // struct containing the address information.
    struct sockaddr_in server;
    
}

@property NSString *version;

// integer port value.
//@property int port;

// NSString variable host value.
//@property char *host;

// NSUinteger buffer value.
//@property NSUInteger buffer;

- (id)initWithHost:(NSString *)nHost withPortInt:(int)nPort;

- (id)initWithHost:(NSString *)nHost withPortNSInt:(NSInteger)nPort;

- (id)sendMessage:(NSString *)message;

- (NSArray *)sendCommand:(Command *)command;

- (void)testConnection;

@end
