//
//  DGSDev.m
//  DGSPhone
//
//  Created by Justin Weiss on 5/8/11.
//  Copyright 2011 Justin Weiss. All rights reserved.
//

#import "DGSDev.h"
#import "ASIFormDataRequest.h"

@implementation DGSDev

// This returns the base path onto which all of the urls used 
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
//
// WARNING: the current CVS checkout of DGS differs significantly
// from the running version -- therefore, you may run into bugs when
// switching back to the real server.

- (NSURL *)baseURL {
    return [NSURL URLWithString:@"http://localhost/~jweiss/DragonGoServer"];
}

@end
