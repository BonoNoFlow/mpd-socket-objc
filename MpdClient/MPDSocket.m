//
//  MPDSocket.m
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

// !!!!!!!!!!!!!!!!!!!!!
// !TODO errors gooien?!
// !!!!!!!!!!!!!!!!!!!!!

#import "MPDSocket.h"
//#import "Command.h"

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

@interface MPDSocket ()
- (int)connect:(NSError **)error;
@end

@implementation MPDSocket

@synthesize version;
@synthesize ack;

const char *OK = "OK\0";
const char *ACK = "ACK\0";

- (NSError *)error:(NSString *)value {
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:value forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"Socket" code:101 userInfo:details];
}



- (NSArray *)sendCommand:(Command *)command error:(NSError **)error{
    
    NSMutableArray *replyArray = [[NSMutableArray alloc] init];
    
    ssize_t length, n;
    length = 0;
    
    char buffer[1024];
    
    char *dest, *offset, *p, *processB, *remain;
    remain = NULL;
    
    sock = [self connect:error];
    
    if (sock < 0) {
        //*error = [self error:@"socket is 0, connect() failed!"];
        return nil;
    }
    
    n = write(sock, command->c, strlen(command->c));
    if (n < 0) {
        NSLog(@"ERROR writing");
        // TODO NSERROR
        exit(1);
    }
   
    bzero(buffer, BUFFER_SIZE);
    
    n = read(sock, buffer, BUFFER_SIZE - 1);
    if (n < 0) {
        NSLog(@"ERROR fillbuffer()");
        // TODO NSERROR
        exit(1);
    }
   
    processB = (char *)calloc(n, sizeof(char));
    memcpy(processB, &buffer[0], n * sizeof(char));
    
    while (n != -1) {
        
        offset = processB;
    
        for (p = offset; p <= &processB[n - 1]; p++) {
            if (*p == NEW_LINE) {
                length = p - offset;
                dest = (char *)calloc(length + 1, sizeof(char));
                memcpy(dest, offset, length * sizeof(char));
                dest[length] = '\0';
                [replyArray addObject:[[NSString alloc] initWithCString:dest encoding:NSUTF8StringEncoding]];
                free(dest);
                offset = p + 1;
            }
        }
        
        // break out of the loop if last string 'OK' is added!
        // before checking bytes left and new read of server,
        // as there's nothing left, exit!
        NSString *lastString = [replyArray lastObject];
        if ([lastString isEqualToString:END_RESPONSE]) {
            [replyArray removeLastObject];
            free(remain);
            
            free(processB);
            break;
        } else if ([lastString hasPrefix:ERROR_RESPONSE]) {
            NSLog(@"ERROR %@\n", lastString);
            // TODO throw NSERROR.
            exit(1);
        }
        
        
        // the left over bytes have to be copied
        // to the beginning of the next buffer.
        if (offset <= &processB[n - 1]) {
            
            if (remain) {
                free(remain);
            }
            length = &processB[n - 1] - offset + 1;
            remain = (char *)calloc(length, sizeof(char));
            memcpy(remain, offset, length * sizeof(char));
            
            free(processB);
            
            bzero(buffer, BUFFER_SIZE);
            n = read(sock, buffer, BUFFER_SIZE -1);
            if (n <= 0) {
                break;
            }
            
            processB = (char *)calloc(n + length, sizeof(char));
            memcpy(processB, &remain[0], length * sizeof(char));
            memcpy(processB + length, &buffer[0], n * sizeof(char));
            n = n + length;
            
        } else if (offset > &processB[n - 1]){
            
            free(processB);
            
            bzero(buffer, BUFFER_SIZE);
            n = read(sock, buffer, BUFFER_SIZE - 1);
            if (n <= 0) {
                break;
            }
            
            processB = (char *)calloc(n, sizeof(char));
            memcpy(processB, &buffer[0], n * sizeof(char));
        } else {
            NSLog(@"what just happened!");
        }
                
    }
    
    close(sock);
    
    return [NSArray arrayWithArray:replyArray];
}



// get sockaddr, IPv4 or IPv6:
void *getInAddress(struct sockaddr *sockaddr) {
    
    if (sockaddr->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sockaddr)->sin_addr);
    }
    
    return &(((struct sockaddr_in6 *)sockaddr)->sin6_addr);
}

// connect to the server.
// method gives socket (int) back.
// add error argument withError:(NSError *) error
- (int)connect:(NSError**)error {
    
    int err, flags, ret;
    ssize_t numBytes;
    
    char buffer[20];
    
    struct addrinfo hints, *server, *p;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    // test for ipv4 or 6.
    err = getaddrinfo([_host UTF8String], [_port UTF8String], &hints, &server);
    if (err) {
        *error = [self error:[[NSString alloc] initWithUTF8String: gai_strerror(err)]];
        return -1;
    }
    
    // todo check increment never executed!
    for (p= server; p != NULL; p = p->ai_next) {
        if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
            *error = [self error:[[NSString alloc] initWithUTF8String:strerror(errno)]];
            return -1;
        }
        
        // maybe connect with timeout because on  wrong ip
        // it takes 75 for error is thrown.
        //if (connect(sock, p->ai_addr, p->ai_addrlen) < 0) {
        //    continue;
        //}
        
        fd_set rset, wset;
        struct timeval timeValue;
        err = 0;
        
        // get flags
        flags = fcntl(sock, F_GETFL, 0);
        
        // set flags non blocking
        fcntl(sock, F_SETFL, flags | O_NONBLOCK);
        
        // connect returns "in progress" if everything is ok
        if ((ret = connect(sock, p->ai_addr, p->ai_addrlen)) < 0) {
            if (errno != EINPROGRESS) {
                *error = [self error:[[NSString alloc] initWithUTF8String:strerror(errno)]];
                return -1;
                //continue;
            }
        }
        
        // on connection made, exit loop
        if (ret == 0) {
            //return sock;
            break;
        }
        
        // call selct to wait for the connection
        FD_ZERO(&rset);
        FD_SET(sock, &rset);
        wset = rset;
        timeValue.tv_sec = 5;
        timeValue.tv_usec = 0;
        if ((ret = select(sock + 1, &rset, &wset, NULL, &timeValue)) == 0) {
            close(sock);
            errno = ETIMEDOUT;
            *error = [self error:[[NSString alloc] initWithUTF8String:strerror(errno)]];
            return -1;
        }
        
        // check if connected, is socket write and readable and check for error
        if (FD_ISSET(sock, &rset) || FD_ISSET(sock, &wset)) {
            socklen_t len = sizeof(err);
            if (getsockopt(sock, SOL_SOCKET, SO_ERROR, &err, &len) < 0) {
                return -1;
            }
        }
        
        
        
        break;
    }
    
    // restor flags
    fcntl(sock, F_SETFL, flags);
    
    
    
    
    
    if ((numBytes = read(sock, buffer, 19)) < 0) {
    //if ((numBytes = recv(sock, buffer, 19, 0))) {
        *error = [self error:@"Error: read(....), connect() failed!"];
        //NSLog(@"error by read(....): connect() MPDSocket");
        return -1;
    }
    buffer[numBytes] = '\0';
    
    // on succesfull connection the server replies with:
    // OK MPD 'version'
    // or,
    // ACK ..., on error.
    if (strncmp(OK, buffer, 2) == 0) {
        size_t size = numBytes - 7;
        char dest[size];
        memset(dest, '\0', sizeof(dest));
        strncpy(dest, &buffer[7], size);
        
        version = [[NSString alloc] initWithUTF8String:(dest)];
        
        return sock;
    } else if (strncmp(ACK, buffer, 3) == 0) {
        // trow error.
        ack = [[NSString alloc] initWithUTF8String:buffer];
        NSLog(@"ACK error");
        return 0;
    }
    
    return 0;
}




-(id)initWithHost:(NSString *)nHost port:(NSString *)nPort {
    self = [super init];
    
    if (self) {
        _host = nHost;
        _port = nPort;
        version = @"connect first!";
    }
    return self;
}


@end
