//
//  Command.h
//  MpdClient
//
//  Created by Hendrik Nieuwenhuis on 05/10/16.
//  Copyright © 2016 hendrik nieuwenhuis. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Command : NSObject {
    
    // char command
    @ public const char *c;
    
    
}

- (id)init:(NSString *) command params:(NSString *)params, ...;

@end
