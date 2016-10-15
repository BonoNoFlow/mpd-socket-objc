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

const char *ACK = "ACK";

const char *OK = "OK";

const char NEW_LINE = '\n';

@synthesize version;


void addToBuffer(char *buffer, char **collectBuffer, ssize_t *numBytes, ssize_t *addBufferSize) {
    
    *collectBuffer = realloc(*collectBuffer, *addBufferSize * sizeof(char));
    strcat(*collectBuffer, buffer);
    memset(buffer, 0, *numBytes);
}

- (NSArray *)sendCommand:(Command *)command {
    
    NSMutableArray *replyArray = [[NSMutableArray alloc] init];
    
    ssize_t length, n;
    
    char buffer[1024];
    bzero(buffer, 1023);
    
    char *dest, *offset, *p, *processB, *remain;
    remain = NULL;
    sock = [self connect];
    
    if (sock == 0) {
        NSLog(@"No socket");
        exit(1);
    }
    
    n = write(sock, command->c, strlen(command->c));
    if (n < 0) {
        NSLog(@"ERROR writting");
        exit(1);
    }
   
    n = read(sock, buffer, 1023);
    if (n < 0) {
        NSLog(@"ERROR reading");
        exit(1);
    }
    
    processB = (char *)calloc(n, sizeof(char));
    memcpy(processB, &buffer[0], n * sizeof(char));
    
    while (n != -1) {
        
        offset = processB;
    
        for (p = offset; p <= &processB[n - 1]; p++) {
            if (*p == '\n') {
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
            if (remain) {
                free(remain);
            }
            free(processB);
            break;
        }
        
        
        // the left over bytes have to be copied
        // to the beginning of the next buffer.
        if (offset < &processB[n - 1]) {
            if (remain) {
                free(remain);
            }
            length = &processB[n - 1] - offset + 1;
            remain = (char *) calloc(length, sizeof(char));
            memcpy(remain, offset, length * sizeof(char));
        } else {
            NSLog(@"offset and processB are equal");
            return 0;
        }
        free(processB);
        
        bzero(buffer, 1024);
        n = read(sock, buffer, 1023);
        if (n == -1 || n == 0) {
            break;
        }
        
        processB = (char *)calloc(n + length, sizeof(char));
        memcpy(processB, &remain[0], length);
        memcpy(processB + length, &buffer[0], n);
        n = n + length;
        
    }
    
    close(sock);

    
    return [NSArray arrayWithArray:replyArray];
}

// test method!
- (void)testConnection {
    
    sock = [self connect];
    
    if (sock == 0) {
        NSLog(@"No socket");
        exit(1);
    }
    
    ssize_t reply;
    
    reply = write(sock, "playlistinfo\n", strlen("playlistinfo\n"));
    if (reply < 0) {
        NSLog(@"ERROR writting");
        exit(1);
    }
    
    char buffer[1024];
    bzero(buffer, 1023);
    
    while ((reply = read(sock, buffer, 1023)) != -1) {
        NSLog(@"%s", buffer);
        break;
    }
    
        close(sock);
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
    
    // the number of bytes written.
    ssize_t numBytes;
    
    // the buffer for the bytes.
    char buffer[20];
    
    // struct addrinfo holding the
    // type of socket info.
    //struct addrinfo hints;
    
    // server info, ipv4 or ipv6
    //struct addrinfo *serverInfo;
    
    //struct addrinfo *p;
    
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        NSLog(@"ERROR opening socket");
        return -1;
    }
    
    bzero((char *) &server, sizeof(server));
    
    // todo als testen ipv4 of ipv6 is geimplementeerd
    // if else of address family moet eerder gezet worden.
    server.sin_family = AF_INET;
    
    inet_pton(AF_INET, host, &(server.sin_addr));
    server.sin_port = htons(port);
    
    //int rv;
    
    //char s[INET6_ADDRSTRLEN];
    
    //memset(&hints, 0, sizeof(hints));
    //hints.ai_family = AF_UNSPEC;
    //hints.ai_socktype = SOCK_STREAM;
    
    //if ((rv = getaddrinfo([host UTF8String], port, &hints, &serverInfo)) !=0) {
        //NSLog(@"Error getaddrinfo(): connect() MPDSocket: %s\n", gai_strerror(rv));
        //return -1;
    //}
    
    // loop through all the results and connect to the first we can.
    /*
    for (p = serverInfo; p!= NULL; p = p->ai_next) {
        if ((sock = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == -1) {
            continue;
        }
        
        if (connect(sock, p->ai_addr, p->ai_addrlen) == -1) {
            close(sock);
            continue;
        }
        break;
    }*/
    
    if (connect(sock, (struct sockaddr *)&server, sizeof(server)) < 0) {
        NSLog(@"ERROR connecting");
        return -1;
    }
    
    //if (p == NULL) {
        //NSLog(@"failed to connect: connect() MPDSocket");
        //return -1;
    //}
    
    //inet_ntop(p->ai_family, getInAddress((struct sockaddr *)p->ai_addr), s, sizeof(s));
    //NSLog(@"MPDSocket connecting to %s\n", s);
    
    //freeaddrinfo(serverInfo); // al done with this structure
    
    if ((numBytes = read(sock, buffer, 19)) < 0) {
        NSLog(@"error by recv(....): connect() MPDSocket");
        return -1;
    }
    
    // make it a cstring by ending it with '\0'
    buffer[numBytes] = '\0';
    
    // on succesfull connection the server replies with:
    // OK MPD 'version'
    if (buffer[0] == 'O' && buffer[1] == 'K') {
        size_t size = numBytes - 7;
        char dest[size];
        memset(dest, '\0', sizeof(dest));
        strncpy(dest, &buffer[7], size);
        
        version = [[NSString alloc] initWithUTF8String:(dest)];
        
        return sock;
    }
    
    return 0;
}



- (long)receiveBytes:(void *)buf limit:(long)limit {
    long received = recv(sock, buf, limit, 0);
    if (received < 0) {
        //_lastError = NEW_ERROR(errno, strerror(errno));
    }
    return received;
}

- (long)receiveBytes:(void *)buf count:(long)count {
    long expected = count;
    while (expected > 0) {
        long received = [self receiveBytes:buf limit:expected];
        if (received < 1) {
            break;
        }
        expected -= received;
        buf += received;
    }
    return (count - expected);
}


-(id)initWithHost:(NSString *)nHost withPortInt:(int)nPort {
    self = [super init];
    
    if (self) {
        host = (char *)[nHost UTF8String];
        port = nPort;
    }
    return self;
}

-(id)initWithHost:(NSString *)nHost withPortNSInt:(NSInteger)nPort {
    self = [super init];
    
    if (self) {
        host = (char *)[nHost UTF8String];
        port = (int) nPort;
    }
    return self;
}

@end
