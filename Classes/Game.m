//
//  Game.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Game.h"
#import	"ASIHTTPRequest.h"
#import	"ASIFormDataRequest.h"
#import "DGS.h"

@implementation Game

@synthesize sgfUrl;
@synthesize opponent;
@synthesize gameId;
@synthesize time;
@synthesize color;

#ifndef LOGIC_TEST_MODE

- (NSString *)sgfString {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.sgfUrl];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		return [request responseString];
	}
	return nil;
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment {

}

#endif

- (void)dealloc {
	[sgfUrl release];
	[opponent release];
	[time release];
	[super dealloc];
}

@end
