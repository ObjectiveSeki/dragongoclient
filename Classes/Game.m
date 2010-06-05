//
//  Game.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "Game.h"
#import	"ASIHTTPRequest.h"

@implementation Game

@synthesize sgfUrl;
@synthesize opponent;
@synthesize gameId;

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

- (void)dealloc {
	[sgfUrl release];
	[opponent release];
	[super dealloc];
}

@end
