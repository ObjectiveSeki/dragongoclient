//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import "DGS.h"
#import "CXMLDocument.h"
#import "NewGame.h"

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

- (BOOL)loggedIn:(ASIHTTPRequest *)request {
	NSString *urlString = [[request url] absoluteString];
	NSLog(@"%@", urlString);
	
	BOOL loggedOutURLNotFound = (NSNotFound == [urlString rangeOfString:@"error.php"].location && NSNotFound == [urlString rangeOfString:@"index.php"].location);
	BOOL errorStatusNotFound = (NSNotFound == [[request responseString] rangeOfString:@"#Error:"].location);
	
	if (loggedOutURLNotFound && errorStatusNotFound) {
		return YES;
	} else {
		NSLog(@"Unauthorized");
	}
	return NO;
}


- (NSURL *)URLWithPath:(NSString *)path {
	NSString *baseString = @"http://www.dragongoserver.net";
	//NSString *baseString = @"http://localhost.local/~jweiss/DragonGoServer";
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseString, path]];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	if (NO == [self loggedIn:request]) {
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
	NSURL *url = [self URLWithPath:@"/quick_status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"gotCurrentGames:" forKey:@"selector"]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)gotCurrentGames:(ASIHTTPRequest *)request {
	NSArray *gameList = [self gamesFromCSV:[request responseString]];
	[[self delegate] gotCurrentGames:gameList];
}

- (void)getSgfForGame:(Game *)game {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:game.sgfUrl];
	[request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"gotSgfForGame:", @"selector", game, @"game", nil]];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)gotSgfForGame:(ASIHTTPRequest *)request {
	Game *game = [[request userInfo] objectForKey:@"game"];
	[game setSgfString:[request responseString]];
	[[self delegate] gotSgfForGame:game];
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
	for(NSString *line in lines) {
		NSArray *cols = [line componentsSeparatedByString:@", "];
		if([[cols objectAtIndex:0] isEqual:@"'G'"]) {
			Game *game = [[Game alloc] init];
			[game setGameId:[[cols objectAtIndex:1] intValue]];
			NSString *opponentString = [cols objectAtIndex:2];
			[game setOpponent:[opponentString substringWithRange:NSMakeRange(1, [opponentString length] - 2)]];
			
			[game setSgfUrl:[self URLWithPath:[NSString stringWithFormat:@"/sgf.php?gid=%d", [game gameId]]]];
			if ([[cols objectAtIndex:3] isEqual:@"'W'"]) {
				[game setColor:kMovePlayerWhite];
			} else {
				[game setColor:kMovePlayerBlack];
			}
			
			NSString *timeRemainingString = [cols objectAtIndex:5];
			[game setTime:[timeRemainingString substringWithRange:NSMakeRange(1, [timeRemainingString length] - 2)]];
			
			[games addObject:game];
			[game release];
		}
	}
	return games;
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId {
	int lastMoveNumber = 0; // DGS wants the move number this move is replying to
	NSURL *url = [self URLWithPath:@"/game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
	[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"playedMove:" forKey:@"selector"]];
	[request setPostValue:@"handicap" forKey:@"action"];
	
	NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([moves count] * 2)];

	for (Move *move in moves) {
		[moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
	}
	
	[request setPostValue:moveString forKey:@"stonestring"];
	[moveString release];
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId {
	int lastMoveNumber = moveNumber; // TODO: For some reason this doesn't need to lose one number?
	NSURL *url = [self URLWithPath:@"/game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
	[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"playedMove:" forKey:@"selector"]];
	[request setPostValue:@"done" forKey:@"action"];
	
	if ([changedStones count] > 0) {
		NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([changedStones count] * 2)];
		
		for (Move *move in changedStones) {
			[moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
		}
		
		[request setPostValue:moveString forKey:@"stonestring"];
		[moveString release];
	}
	[request setDelegate:self];
	[request startAsynchronous];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId {
	
	if (lastMove && [lastMove moveType] == kMoveTypeMove && [move moveType] == kMoveTypeMove) {
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
		[request setUserInfo:[NSDictionary dictionaryWithObject:@"playedMove:" forKey:@"selector"]];
		[request setDelegate:self];
		
		[request startAsynchronous];
		
	} else {
		// can't respond using quick_play.php
		int lastMoveNumber = moveNumber - 1; // DGS wants the move number this move is replying to
		NSURL *url = [self URLWithPath:@"/game.php"];
		
	    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
		[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
		[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
		[request setUserInfo:[NSDictionary dictionaryWithObject:@"playedMove:" forKey:@"selector"]];
		if ([move moveType] == kMoveTypePass) {
			[request setPostValue:@"pass" forKey:@"action"];
		} else if ([move moveType] == kMoveTypeResign) {
			[request setPostValue:@"resign" forKey:@"action"];
		} else if ([move moveType] == kMoveTypeMove) {
			[request setPostValue:@"domove" forKey:@"action"];
			[request setPostValue:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]] forKey:@"coord"];
		}
		[request setDelegate:self];
		[request startAsynchronous];
	}
}

- (void)playedMove:(ASIHTTPRequest *)request {
	[[self delegate] playedMove];
}

- (void)addGame:(NewGame *)game {
	NSURL *url = [self URLWithPath:@"/add_to_waitingroom.php"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game numberOfGames]] forKey:@"nrGames"];
	[request setPostValue:[game ruleSetValue] forKey:@"ruleset"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game boardSize]] forKey:@"size"];
	[request setPostValue:[game komiTypeValue] forKey:@"cat_htype"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game adjustedHandicap]] forKey:@"adj_handicap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game minHandicap]] forKey:@"min_handicap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game maxHandicap]] forKey:@"max_handicap"];
	[request setPostValue:[game boolValue:[game stdHandicap]] forKey:@"stdhandicap"];
	[request setPostValue:[NSString stringWithFormat:@"%f", [game adjustedKomi]] forKey:@"adj_komi"];
	[request setPostValue:[game jigoModeValue] forKey:@"jigo_mode"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game timeValue]] forKey:@"timevalue"];
	[request setPostValue:[game timePeriodValue:[game timeUnit]] forKey:@"timeunit"];
	[request setPostValue:[game byoYomiTypeValue] forKey:@"timeunit"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimeValue]] forKey:@"byotimevalue_jap"];
	[request setPostValue:[game timePeriodValue:[game japaneseTimeUnit]] forKey:@"timeunit_jap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimePeriods]] forKey:@"byoperiods_jap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimeValue]] forKey:@"byotimevalue_can"];
	[request setPostValue:[game byoYomiTypeValue] forKey:@"byoyomitype"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimePeriods]] forKey:@"byoperiods_can"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game fischerTimeValue]] forKey:@"byotimevalue_fis"];
	[request setPostValue:[game timePeriodValue:[game fischerTimeUnit]] forKey:@"timeunit_fis"];

	[request setPostValue:[game boolValue:[game weekendClock]] forKey:@"weekendclock"];
	[request setPostValue:[game boolValue:[game rated]] forKey:@"rated"];
	[request setPostValue:[game minimumRating] forKey:@"rating1"];
	[request setPostValue:[game maximumRating] forKey:@"rating2"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game sameOpponent]] forKey:@"same_opp"];	
	[request setPostValue:[game comment] forKey:@"comment"];
	[request setPostValue:@"Add Game" forKey:@"add_game"];
	
	
	[request setUserInfo:[NSDictionary dictionaryWithObject:@"addedGame:" forKey:@"selector"]];
	[request setDelegate:self];
	
	[request startAsynchronous];
}

- (void)addedGame:(ASIHTTPRequest *)request {
	[[self delegate] addedGame];
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
