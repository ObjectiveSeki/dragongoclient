//
//  Game.m
//
//	Represents a game, as DGS sees it. This is pretty much a struct, 
//  all of the complicated logic is inside FuegoBoard.
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "Game.h"
#import "DGS.h"

@implementation Game

@synthesize sgfUrl;
@synthesize sgfString;
@synthesize opponent;
@synthesize gameId;
@synthesize detailUrl;
@synthesize time;
@synthesize color;
@synthesize opponentRating;
@synthesize handicap;
@synthesize komi;

- (void)dealloc {
	self.detailUrl = nil;
	[sgfString release];
	[sgfUrl release];
	[opponent release];
	[time release];
	self.opponentRating = nil;
	[super dealloc];
}

@end
