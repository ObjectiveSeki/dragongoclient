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

@synthesize delegate;

#ifndef LOGIC_TEST_MODE


- (id)init {
	if ([super init]) {
		
	}
	return self;
}

- (BOOL)loggedIn:(NSString *)response {
	if (NSNotFound == [response rangeOfString:@"Logged in as:"].location) {
		NSLog(@"Unauthorized");
	} else {
		return YES;
	}
	return NO;
}


- (NSURL *)URLWithPath:(NSString *)path {
	//NSString *baseString = @"http://www.dragongoserver.net";
	NSString *baseString = @"http://localhost/~jweiss/DragonGoServer";
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseString, path]];
}

- (BOOL)loggedIn {
	NSURL *url = [self URLWithPath:@"/status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	
	NSError *error = [request error];
	if (!error) {
		return [self loggedIn:[request responseString]];
	}
	return NO;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSString *response = [request responseString];
	NSLog(@"%@", response);
	if (NO == [self loggedIn:response]) {
		[[self delegate] notLoggedIn];
	} else {
		SEL selector = NSSelectorFromString([[request userInfo] objectForKey:@"selector"]);
		if (selector && [self respondsToSelector:selector]) {
			[self performSelector:selector withObject:request];
		}
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"%@", error);
}

- (void)logout {
	NSURL *url = [self URLWithPath:@"/index.php?logout=t"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password 
{
	
	NSURL *url = [self URLWithPath:@"/login.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:username forKey:@"userid"];
	[request setPostValue:password forKey:@"passwd"];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"didLogin:" forKey:@"selector"]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)didLogin:(ASIHTTPRequest *)request {
	[[self delegate] loggedIn];
}

- (void)getCurrentGames {
	NSURL *url = [self URLWithPath:@"/status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"gotCurrentGames:" forKey:@"selector"]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)gotCurrentGames:(ASIHTTPRequest *)request {
	NSArray *gameList = [self gamesFromTable:[request responseString]];
	[[self delegate] gotCurrentGames:gameList];
}

#endif


- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize
{
	char rowChar = 'a' + (boardSize - row);
	char colChar = 'a' + (col - 1);
	return [NSString stringWithFormat:@"%c%c", colChar, rowChar];
}

- (NSArray *)gamesFromCSV:(NSString *)csvData {
	NSMutableArray *games = [NSMutableArray array];
	NSArray *lines = [csvData componentsSeparatedByString:@"\n"];
	return games;
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId {
	
	if ([move moveType] == kMoveTypePass) {
		int lastMoveNumber = moveNumber - 1; // DGS wants the move number this move is replying to
		NSURL *url = [self URLWithPath:@"/game.php"];
	    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
		[request setPostValue:@"pass" forKey:@"action"];
		[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
		[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
		[request startAsynchronous];
	} else {
		NSURL *url = [self URLWithPath:@"/quick_play.php"];
		ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
		
		if ([move player] == kMovePlayerBlack) {
			[request setPostValue:@"B" forKey:@"color"];
		} else {
			[request setPostValue:@"W" forKey:@"color"];
		}
		
		[request setPostValue:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]] forKey:@"sgf_move"];
		
		[request setPostValue:[self sgfCoordsWithRow:[lastMove row] column:[lastMove col] boardSize:[lastMove boardSize]] forKey:@"sgf_prev"];
		
		[request startAsynchronous];
	}
}

- (NSArray *)gamesFromTable:(NSString *)htmlString {
	NSMutableArray *games = [NSMutableArray array];
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:htmlString options:CXMLDocumentTidyHTML error:&error];
	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='gameTable']/tr" error:&error];

    if ([tableRows count] == 0) {
		return games;
	}
	
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
				game.sgfUrl = [self URLWithPath:data];
			} else if ([headerName isEqual:@"Time remaining"]) {
				CXMLNode *td = [columns objectAtIndex:i];
				NSString *data = [td stringValue];
				game.time = data;
			}  else if ([headerName isEqual:@"Col"]) {
				CXMLNode *td = [columns objectAtIndex:i];
				NSString *data = [[[td nodesForXPath:@"img/@alt" error:&error] objectAtIndex:0] stringValue];
				if ([data isEqual:@"b"]) {
					game.color = kMovePlayerBlack;
				} else {
					game.color = kMovePlayerWhite;
				}
			}
		}
		
		[games addObject:game];
		[game release];
		
	}
	
	[doc release];
	return games;
}

- (void)dealloc {
    [super dealloc];
}

@end
