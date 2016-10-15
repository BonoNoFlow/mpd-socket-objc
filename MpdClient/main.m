//
//  main.m
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPDSocket.h"
#import "Command.h"

#include <sys/socket.h>
#include <string.h>


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MPDSocket *socket = [[MPDSocket alloc] initWithHost:@"192.168.2.4" withPortNSInt:6600 ];
        
        int sock = [socket connect];
        
        if (sock != -1) {
            NSLog(@"got sock!");
        }
        
        Command *command = [[Command alloc] init:@"lsinfo" params: nil];
        
        NSArray *replyArray = [socket sendCommand:command];
        
        for (NSString *string in replyArray) {
            NSLog(@"%@\n", string);
        }
                
    }
    return 0;
}
