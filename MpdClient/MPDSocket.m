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

@implementation MPDSocket

@synthesize version;
@synthesize error;

const char *OK = "OK\0";
const char *ACK = "ACK\0";


- (NSArray *)sendCommand:(Command *)command {
    
    NSMutableArray *replyArray = [[NSMutableArray alloc] init];
    
    ssize_t length, n;
    length = 0;
    
    char buffer[1024];
    
    char *dest, *offset, *p, *processB, *remain;
    remain = NULL;
    
    sock = [self connect];
    
    if (sock == 0) {
        NSLog(@"No socket");
        // TODO NSERROR
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
- (int)connect {
    
    ssize_t numBytes;
    
    char buffer[20];
    
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        NSLog(@"ERROR opening socket");
        return -1;
    }
    
    bzero((char *) &server, sizeof(server));
    
    // TODO test for ipv4 or 6.
    
    server.sin_family = AF_INET;
    
    inet_pton(AF_INET, host, &(server.sin_addr));
    server.sin_port = htons(port);
    
    if (connect(sock, (struct sockaddr *)&server, sizeof(server)) < 0) {
        NSLog(@"ERROR connecting");
        return -1;
    }
    
    if ((numBytes = read(sock, buffer, 19)) < 0) {
        NSLog(@"error by recv(....): connect() MPDSocket");
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
        error = [[NSString alloc] initWithUTF8String:buffer];
        NSLog(@"ACK error");
        return 0;
    }
    
    return 0;
}




-(id)initWithHost:(NSString *)nHost withPortInt:(int)nPort {
    self = [super init];
    
    if (self) {
        host = (char *)[nHost UTF8String];
        port = nPort;
        version = @"connect first!";
    }
    return self;
}

-(id)initWithHost:(NSString *)nHost withPortNSInt:(NSInteger)nPort {
    self = [super init];
    
    if (self) {
        host = (char *)[nHost UTF8String];
        port = (int) nPort;
        version = @"connect first";
    }
    return self;
}

@end
