//
//  DGSDev.m
//  DGSPhone
//
//  Created by Justin Weiss on 5/8/11.
//  Copyright 2011 Justin Weiss. All rights reserved.
//

#import "DGSDev.h"

@implementation DGSDev

// This returns the base path onto which all of the urls used 
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
//
// WARNING: the current CVS checkout of DGS differs significantly
// from the running version -- therefore, you may run into bugs when
// switching back to the real server.

- (id)init
{
    //return [self initWithHostName:@"localhost:8080" apiPath:nil customHeaderFields:[self defaultCustomHeaderFields]];
    return [self initWithHostName:@"dragongoserver.sourceforge.net" apiPath:nil customHeaderFields:[self defaultCustomHeaderFields]];
}


@end
