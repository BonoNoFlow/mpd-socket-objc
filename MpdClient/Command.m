//
//  Command.m
//  MpdClient
//
//  Created by Hendrik Nieuwenhuis on 05/10/16.
//  Copyright © 2016 hendrik nieuwenhuis. All rights reserved.
//

#import "Command.h"

@implementation Command

- (id)init:(NSString *)command params:(NSString *)params, ... {
    
    NSMutableArray *buffer = [NSMutableArray array];
    [buffer addObject:command];
    
    // todo add to mutable string.
    
    va_list args;
    va_start(args, params);
    for (NSString *arg = params; arg != nil; arg = va_arg(args, NSString*)) {
        [buffer addObject:[[NSString alloc] initWithString:arg]];
    }
    
    
    NSString *cc = [buffer componentsJoinedByString:@" "];
    NSMutableString *mString = [[NSMutableString alloc] initWithString:cc];
    [mString appendString:@"\n"];
    c = [mString cStringUsingEncoding:NSUTF8StringEncoding];
    va_end(args);
    return self;
}

@end
