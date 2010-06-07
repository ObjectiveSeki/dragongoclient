//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "DGS.h"
#import "Game.h"
#import "CXMLDocument.h"

#ifndef LOGIC_TEST_MODE
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#endif

@implementation DGS

#ifndef LOGIC_TEST_MODE

+ (void)logout {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/index.php?logout=t"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
}

+ (BOOL)loggedIn {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	
	NSError *error = [request error];
	if (!error) {
		if (NSNotFound == [[request responseString] rangeOfString:@"you have to be logged in"].location) {
			NSLog(@"%@", [request responseString]);
			return YES;
		} else {
			NSLog(@"Unauthorized");
		}
	}
	return NO;
}

+ (void)loginWithUsername:(NSString *)username password:(NSString *)password 
{
	
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/login.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:username forKey:@"userid"];
	[request setPostValue:password forKey:@"passwd"];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
	}
}

+ (NSArray *)currentGames {
	NSURL *url = [NSURL URLWithString:@"http://www.dragongoserver.net/status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	NSError *error = [request error];
	NSArray *gameList;
	if (!error) {
		gameList = [DGS gamesFromTable:[request responseString]];
	}
	return gameList;
}

#endif

+ (NSArray *)gamesFromCSV:(NSString *)csvData {
	NSMutableArray *games = [NSMutableArray array];
	NSArray *lines = [csvData componentsSeparatedByString:@"\n"];
	return games;
}

+ (NSArray *)gamesFromTable:(NSString *)htmlString {
	NSMutableArray *games = [NSMutableArray array];
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:htmlString options:CXMLDocumentTidyHTML error:&error];
	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='gameTable']/tr" error:&error];

	// TODO: make sure we have rows!!
	
	// First row is the header
	CXMLNode *headerRow = [tableRows objectAtIndex:0];
	NSArray *columns = [headerRow nodesForXPath:@".//span[@class='Header']" error:&error];
	
	NSMutableArray *tableHeaders = [NSMutableArray arrayWithCapacity:[columns count]];
	for (CXMLNode *column in columns) {
		[tableHeaders addObject:[column stringValue]];
	}
	
	// trim the header row
	NSRange range;
	range.location = 1;
	range.length = [tableRows count] - 1;
	
	for (CXMLNode *row in [tableRows subarrayWithRange:range]) {
		
		NSArray *columns = [row nodesForXPath:@"td" error:&error];
		
		// bad things happen if these counts aren't equal
		if ([columns count] != [tableHeaders count]) {
			continue;
		}
			
		Game *game = [[Game alloc] init];
		
		for(int i = 0; i < [tableHeaders count]; i++) {
			NSString *headerName = [tableHeaders objectAtIndex:i];
			if ([headerName isEqual:@"ID"]) {
				CXMLNode *td = [columns objectAtIndex:i];
				NSString *data = [[[td nodesForXPath:@"a" error:&error] objectAtIndex:0] stringValue];
				game.gameId = [data integerValue];
			} else if ([headerName isEqual:@"Opponent"]) {
				CXMLNode *td = [columns objectAtIndex:i];
				NSString *data = [[[td nodesForXPath:@"a/font" error:&error] objectAtIndex:0] stringValue];
				game.opponent = [data stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if ([headerName isEqual:@"sgf"]) {
				CXMLNode *td = [columns objectAtIndex:i];
				NSString *data = [[[td nodesForXPath:@"a/@href" error:&error] objectAtIndex:0] stringValue];
				game.sgfUrl = [NSString stringWithFormat:@"%@%@", @"http://www.dragongoserver.net/", data];
			}
		}
		
		[games addObject:game];
		[game release];
		
	}
	
	[doc release];
	return games;
}
@end
