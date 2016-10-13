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

// String met address HOST!
//@synthesize host;

// integer met PORT nummer!
//@synthesize port;



void addToBuffer(char *buffer, char **collectBuffer, ssize_t *numBytes, ssize_t *addBufferSize) {
    
    *collectBuffer = realloc(*collectBuffer, *addBufferSize * sizeof(char));
    strcat(*collectBuffer, buffer);
    memset(buffer, 0, *numBytes);
}

- (id)sendMessage:(NSString *)message {
    
    sock = [self connect];
    
    // has to become an error or log and return.
    if (sock == 0) {
        NSLog(@"connect(): Failed return 0");
        return nil;
    }
    
    if (sock == -1) {
        NSLog(@"connect(): Failed return -1");
        return nil;
    }
    
    const char *command = [message UTF8String];
        
    if (send(sock, command, sizeof(command), 0) < 0) {
        NSLog(@"Send command failed!");
        return nil;
    }
    
    // read the feedback of the server.
    // ssize_t numBytes = 0;
    char buffer[BUFFER_SIZE];
    
    // size of addBuffer where
    // the filled buffer is added to.
    // size increases by numBytes
    // when bytes are written.
    ssize_t addBufferSize = 1;
    char *addBuffer = malloc(sizeof(char) * addBufferSize);
    addBuffer[0] = '\0';
    
    // clear buffer!
    memset(buffer, 0, BUFFER_SIZE);
    
    // TODO fill buffer,
    // add buffer to stored buffer.
    // read string or strings from stored buffer,
    // store remaining data,
    // next fill ...
    
    ssize_t readBytes;
    
    
    NSLog(@"entering while lopp");
    //
    // while written to buffer.
    
    readBytes = read(sock, buffer, BUFFER_SIZE - 1);
    NSLog(@"%ld\n", readBytes);
    while ((readBytes = recv(sock, buffer, (BUFFER_SIZE - 1), 0)) != -1) {
        printf("Bytes written\n");
        // 0 when socket is shut by remote.
        // normally client has to close connection.
        if (readBytes == 0) {
            break;
        }
        
        if (readBytes == -1) {
            break;
        }
        
        // copy read buffer to what is left over from last read.
        
        // iterate through the buffer searching for '\n'.
        int offset = 0;
        
        int i = 0;
        
        char *dest;
        for (; i < readBytes ; i++) {
            if (buffer[i] == NEW_LINE) {
                
                int length = i - offset;
                dest = (char *) calloc(length, sizeof(char));
                memcpy(dest, &buffer[offset], length);
                
                printf("%s\n", dest);
                
                offset = i + 1;
                
                free(dest);
            }
            
        }
        printf("%s\n", buffer);
        //free(dest);
        /*
        for (p = &buffer[0]; p < (buffer +readBytes); p++) {
            
            if (*p == new_line) {
                //printf("found%c", *p);
                ptrdiff_t index = p - buffer;
                ptrdiff_t offset = offsetP - buffer;
                ptrdiff_t length = index - offset;
                char dest[length];
                memcpy(dest, offsetP, length);
                NSString *out = [[NSString alloc] initWithUTF8String:dest];
                NSLog(@"%@\n", out);
                offsetP = p;
            }
        }*/
        
        
    }
    //
    //  buffer stored.
    //
    //  if !stored.
    //    new stored.
    //    add data to stored.
    //  else.
    //    add data to stored.
    //
    //  int countEnters = 0;
    //  for int i = 0 ; i < stored.size ; i++
    //
    //      if stored[i] == \n
    //          add 
    //          countEnters = i;
    //
    //
    //  process stored.
    //    add strings to NSMutableArray.
    //
    //  assign whats left in stored to stored.
    //
    
    //numBytes = recv(sock, buffer, (BUFFER_SIZE - 1), 0);
    /*
    while (1) {
        numBytes = recv(sock, buffer, (BUFFER_SIZE - 1), 0);
        addBufferSize += numBytes;
        buffer[numBytes] = '\0';
        
        if (numBytes == -1) {
            perror("recv");
            exit(1);
        } else if (strstr(buffer, end_line)) {
            addToBuffer(buffer, &addBuffer, &numBytes, &addBufferSize);
            break;
        }
        addToBuffer(buffer, &addBuffer, &numBytes, &addBufferSize);
        
        numBytes = 0;
    }
    
    NSString *reply = [[NSString alloc] initWithUTF8String:addBuffer];
    return reply;*/
    return nil;
}

- (NSArray *)sendCommand:(Command *)command {
    //NSLog(@"%s\n", command->c);
    NSMutableArray *replyArray = [[NSMutableArray alloc] init];
    ssize_t replyBytes;
    
    sock = [self connect];
    
    if (sock == 0) {
        NSLog(@"No socket");
        exit(1);
    }
    
    replyBytes = write(sock, command->c, strlen(command->c));
    if (replyBytes < 0) {
        NSLog(@"ERROR writting");
        exit(1);
    }
    
    char buffer[1024];
    bzero(buffer, 1023);
    
    // todo copy leftover bytes to storage and ad it to the next buffer.
    BOOL bytesLeft;
    
    replyBytes = read(sock, buffer, 1023);
    
    while (replyBytes != -1) {
    
    //while ((replyBytes = read(sock, buffer, 1023)) != -1) {
        
        int offset = 0;
        
        int i = 0;
        
        char *dest;
        
        // iterate through the buffer searching for '\n'.
        // add the found char[]'s to the nsmutablearray.
        for (; i < replyBytes ; i++) {
            if (buffer[i] == NEW_LINE) {
                
                int length = (i - offset) + 1;
                dest = (char *) calloc(length, sizeof(char));
                memcpy(dest, &buffer[offset], (length - 1));
                dest[(length - 1)] = '\0';
                
                NSString *feedback = [[NSString alloc] initWithCString:dest encoding:NSUTF8StringEncoding];
                
                // !!!!!! _____ TODO waarschijnlijk niet meer nodig_____ !!!!!!
                if (feedback != nil) {
                    [replyArray addObject:feedback];
                } else {
                    // log feedback nil.
                    // storage left over bytes problem???
                    NSLog(@"feedback is nil");
                }
                
                offset = i + 1;
                free(dest);
            }
        }
        
        // break out of the loop if last string 'OK' is added!
        // before checking bytes left and new read of server,
        // as there's nothing left, exit!
        NSString *lastString = [replyArray lastObject];
        if ([lastString isEqualToString:@"OK"]) {
            [replyArray removeLastObject];
            break;
        }

        
        // the left over bytes have to copied
        // at the beginning of the next buffer.
        if (replyBytes >= offset) {
            NSLog(@"bytes left");
            bytesLeft = YES;
            
            if (replyBytes == offset) {
                NSLog(@"replyBytes == offset");
            } else if (replyBytes > offset) {
                NSLog(@"replyBytes > offset");
            }
        }
        
        
        
        replyBytes = read(sock, buffer, 1023);
    }
    
    if (replyBytes == -1) {
        //return nil;
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
