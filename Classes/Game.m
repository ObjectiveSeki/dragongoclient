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
	NSURL *url = [NSURL URLWithString:self.sgfUrl];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		return [request responseString];
	}
	return nil;
}

- (void)playMove:(Stone *)move lastMove:(Stone *)lastMove comment:(NSString *)comment {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/quick_play.php"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", [self gameId]] forKey:@"gid"];

	if ([move player] == kStonePlayerBlack) {
		[request setPostValue:@"B" forKey:@"color"];
	} else {
		[request setPostValue:@"W" forKey:@"color"];
	}
	
	[request setPostValue:[DGS sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]] forKey:@"sgf_move"];
	
	[request setPostValue:[DGS sgfCoordsWithRow:[lastMove row] column:[lastMove col] boardSize:[lastMove boardSize]] forKey:@"sgf_prev"];

    [request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSLog(@"%@", [request responseString]);
	}
}

#endif

- (void)dealloc {
	[sgfUrl release];
	[opponent release];
	[time release];
	[super dealloc];
}

@end
