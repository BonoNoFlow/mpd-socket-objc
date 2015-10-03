//
//  main.m
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPDSocket.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MPDSocket *socket = [[MPDSocket alloc] initWithHost:@"192.168.2.2" port:@"6600"];
        
        
        
        NSLog(@"%@ %@",socket.host, socket.port);
        
        [socket testConnection];
    }
    return 0;
}
