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
                
        Command *command = [[Command alloc] init:@"statis" params: nil];
        
        NSArray *replyArray = [socket sendCommand:command];
        
        if (replyArray != nil) {
            for (NSString *string in replyArray) {
                NSLog(@"hello: %@\n", string);
            }
        } else {
            NSLog(@"%@\n", [socket error]);
        }
        
    }
    return 0;
}
