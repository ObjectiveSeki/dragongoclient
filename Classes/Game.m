//
//  Game.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Game.h"


@implementation Game

@synthesize sgfUrl;
@synthesize opponent;
@synthesize gameId;

- (void)dealloc {
	[sgfUrl release];
	[opponent release];
	[super dealloc];
}

@end
