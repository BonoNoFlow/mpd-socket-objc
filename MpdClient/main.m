//
//  main.m
//  MpdClient
//
//  Created by hendrik nieuwenhuis on 23/09/15.
//  Copyright © 2015 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "MPDSocket.h"
#import "Command.h"

#include <sys/socket.h>
#include <string.h>


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MPDSocket *socket = [[MPDSocket alloc] initWithHost:@"192.168.2.4" port:@"6600"];
                
        Command *command = [[Command alloc] init:@"playlistinfo" params: nil];
        
        //NSError *error = [NSError errorWithDomain:@"main" code:101 userInfo:@{@"Error reason": @"Test"}];
        NSError *error = nil;
        NSArray *replyArray = [socket sendCommand:command error:&error];
        
        if (error) {
            NSLog(@"%@\n", error);
            return 0;
        } else {
            for (NSString *string in replyArray) {
                NSLog(@"hello: %@\n", string);
            }
        }
    }
    return 0;
}
