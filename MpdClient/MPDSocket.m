//
//  MPDSocket.m
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import "MPDSocket.h"

@implementation MPDSocket

// String met address HOST!
@synthesize host;

// integer met PORT nummer!
@synthesize port;



void addToBuffer(char *buffer, char **collectBuffer, ssize_t *numBytes, ssize_t *addBufferSize) {
    
    *collectBuffer = realloc(*collectBuffer, *addBufferSize * sizeof(char));
    strcat(*collectBuffer, buffer);
    memset(buffer, 0, *numBytes);
}

// test method!
- (void)testConnection {
    
    sock = [self connect];
    
    if (sock == 0) exit(1);
    
    // send a message 'status\n' to receive
    // the status of the server.
    char message[9] = "playlist\n";
    
    if (send(sock, message, strlen(message), 0) < 0) NSLog(@"Send failed!");
    
    // read the feedback of the server.
    ssize_t numBytes = 0;
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
    
    while (1) {
        
        numBytes = recv(sock, buffer, (BUFFER_SIZE - 1), 0);
        addBufferSize += numBytes;
        buffer[numBytes] = '\0';
        if (numBytes == -1) {
            perror("recv");
            exit(1);
        
        } else if (numBytes < (BUFFER_SIZE - 1) && (strstr(buffer, END_RESPONSE) != NULL)) {
            
            addToBuffer(buffer, &addBuffer, &numBytes, &addBufferSize);
            break;
        }
        
        addToBuffer(buffer, &addBuffer, &numBytes, &addBufferSize);
        
        numBytes = 0;
        
    }
    
    NSString *status = [[NSString alloc] initWithUTF8String:addBuffer];
    NSLog(@"%@", status);

    //printf("Client recieved:\n%ssize: %zd\n", addBuffer, addBufferSize);
    
    free(addBuffer);
    
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
- (int)connect {
    
    // the number of bytes written.
    ssize_t numBytes;
    
    // the buffer for the bytes.
    char buffer[20];
    
    // struct addrinfo holding the
    // type of socket info.
    struct addrinfo hints;
    
    // server info, ipv4 or ipv6
    struct addrinfo *serverInfo;
    
    struct addrinfo *p;
    
    int flag;
    
    int rv;
    
    char s[INET6_ADDRSTRLEN];
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    if ((rv = getaddrinfo([host UTF8String], [port UTF8String], &hints, &serverInfo)) !=0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }
    
    // loop through all the results and connect to the first we can.
    for (p = serverInfo; p!= NULL; p = p->ai_next) {
        if ((sock = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == -1) {
            perror("Client: connect");
            continue;
        }
        
        if (connect(sock, p->ai_addr, p->ai_addrlen) == -1) {
            close(sock);
            perror("Client: connect");
            continue;
        }
        break;
    }
    
    if (p == NULL) {
        fprintf(stderr, "Client: failed to connect\n");
        return 2;
    }
    
    inet_ntop(p->ai_family, getInAddress((struct sockaddr *)p->ai_addr), s, sizeof(s));
    printf("Client connecting to %s\n", s);
    
    freeaddrinfo(serverInfo); // al done with this structure
    
    if ((numBytes = recv(sock, buffer, 19, 0)) == -1) {
        perror("recv");
        exit(1);
    }
    
    buffer[numBytes] = '\0';
    
    printf("Client: recieved %s%zd\n", buffer, numBytes);
    
    
    
    return sock;
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

// method die Object initializeerd!
-(id)initWithHost:(NSString *)initHost port:(NSString *)initPort {
    self = [super init];
    
    if (self) {
        host = initHost;
        port = initPort;
        
        
    }
    return self;
}
//

// method dealoc!

@end
