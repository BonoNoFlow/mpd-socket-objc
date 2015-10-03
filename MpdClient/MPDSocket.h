//
//  MPDSocket.h
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>

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

// buffer size 20 causes
// blocking on the recv
// method of the socket
// when the server is
// stopped
#define BUFFER_SIZE 1024

#define END_RESPONSE "OK\n"

@interface MPDSocket : NSObject {
    
    // integer pointer address to the socket.
    int sock;
    
    // struct containing the address information.
    struct sockaddr_in server;
    
}

// integer port value.
@property NSString *port;

// NSString variable host value.
@property NSString *host;

// NSUinteger buffer value.
@property NSUInteger buffer;

-(id)initWithHost:(NSString *)initHost port:(NSString *) initPort;

-(void)testConnection;

@end
