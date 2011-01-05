//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGS.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "NewGame.h"

#ifndef LOGIC_TEST_MODE
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "DGSPhoneAppDelegate.h"

typedef void (^ASIHTTPRequestBlock)(ASIHTTPRequest *request);
#endif

@implementation DGS

@synthesize delegate;


// This returns the base path onto which all of the urls used 
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
//
// WARNING: the current CVS checkout of DGS differs significantly
// from the running version -- therefore, you may run into bugs when
// switching back to the real server.
- (NSURL *)URLWithPath:(NSString *)path {
	NSString *baseString = @"http://www.dragongoserver.net";
	//NSString *baseString = @"http://localhost.local/~jweiss/DragonGoServer";
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseString, path]];
}

#ifndef LOGIC_TEST_MODE

- (id)init {
	if ([super init]) {
		 [ASIHTTPRequest setDefaultTimeOutSeconds:15];
	}
	return self;
}

#pragma mark -
#pragma mark Request handling

// Is the user currently logged in through their cookie? YES if so,
// NO if not. 
- (BOOL)loggedIn:(ASIHTTPRequest *)request {
	NSString *urlString = [[request url] absoluteString];
	
	// Use a simple heuristic here. If we are hitting a normal HTML page, we
	// can figure out if the user is logged in by checking if we ended up on index.php
	// or error.php (in the case where the error is not_logged_in)
	BOOL onErrorPageOrIndex = (NSNotFound != [urlString rangeOfString:@"error.php?err=not_logged_in"].location || NSNotFound != [urlString rangeOfString:@"index.php"].location);
	
	// If we're using the DGS api, it will return the string 'Error: no_uid' or 'Error: not_logged_in' if we aren't logged in.
	BOOL noUID = (NSNotFound != [[request responseString] rangeOfString:@"#Error: no_uid"].location);
	BOOL notLoggedIn = (NSNotFound != [[request responseString] rangeOfString:@"#Error: not_logged_in"].location);
	
	if (onErrorPageOrIndex || noUID || notLoggedIn ) {
		return NO;
	}
	return YES;
}

// Checks the request body to see if it contains an error. If so,
// return the error string. Otherwise, returns nil.
- (NSString *)error:(ASIHTTPRequest *)request {
	NSString *urlString = [[request url] absoluteString];
	NSString *errorString = nil;
	
	if (NSNotFound != [urlString rangeOfString:@"error.php"].location) {
		NSError *error;
		CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:[request responseString] options:CXMLDocumentTidyHTML error:&error];
		NSArray *bodyElements = [doc nodesForXPath:@"//td[@id='pageBody']" error:&error];
		if ([bodyElements count] > 0) {
			errorString = [[bodyElements objectAtIndex:0] stringValue];
		}
		[doc release];
	}
	
	return errorString;
}

// Called when the AlertView containing an error message is dismissed.
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[alertView release];
	[[self delegate] requestCancelled];
}

// Called when an ASIHTTPRequest finishes. Handles being logged out, 
// error messages, and successes. 
- (void)requestFinished:(ASIHTTPRequest *)request
{
	//NSLog(@"%@", [request responseString]);
	NSString *errorString = [self error:request];
	if (NO == [self loggedIn:request]) {
		JWLog(@"Not logged in during request: %@", [request url]);
		[[self delegate] notLoggedIn];
	} else if (errorString) {
		JWLog(@"Error during request: %@\n  Error: %@", [request url], errorString);
		
		[[[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}  else {
		JWLog(@"%@: %@", [request url], [request responseString]);
		ASIHTTPRequestBlock onSuccess = [[request userInfo] objectForKey:@"onSuccess"];
		
		if (onSuccess) {
			onSuccess(request);
		}
	}
}

// Called when a request fails entirely.
- (void)requestFailed:(ASIHTTPRequest *)request
{
	JWLog(@"Request failed: %@", [request url]);
	[[[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"There was a problem communicating with the server." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

// Starts an asynchronous request, calling onSuccess when the request finishes.
- (void)performRequest:(ASIHTTPRequest *)request onSuccess:(ASIHTTPRequestBlock)onSuccess {
	JWLog(@"Performing request: %@", [request url]);
	
	NSMutableDictionary *userInfo = [request.userInfo mutableCopy];
	
	if (!userInfo) {
		userInfo = [[NSMutableDictionary alloc] init];
	}
	
	if (onSuccess) {
		[userInfo setObject:[[onSuccess copy] autorelease] forKey:@"onSuccess"];
	}
	
	request.userInfo = userInfo;
	[userInfo release];
	
	request.delegate = self;
	[request startAsynchronous];
}

#pragma mark -
#pragma mark DGS Calls


- (void)logout {
	NSURL *url = [self URLWithPath:@"/index.php?logout=t"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

	// Success is meaningless here, since we have special handling for being
	// logged out during a request
	[self performRequest:request onSuccess:nil];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
	
	NSURL *url = [self URLWithPath:@"/login.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:username forKey:@"userid"];
	[request setPostValue:password forKey:@"passwd"];
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		[self.delegate loggedIn];
	}];
}

- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess {
	NSURL *url = [self URLWithPath:@"/quick_status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		NSArray *gameList = [self gamesFromCSV:[request responseString]];
		onSuccess(gameList);
	}];
}

- (void)getWaitingRoomGames:(void (^)(NSArray *gameList))onSuccess {
	NSURL *url = [self URLWithPath:@"/waiting_room.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		NSArray *gameList = [self gamesFromWaitingRoomTable:[request responseString]];
		onSuccess(gameList);
	}];
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:game.sgfUrl];
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		[game setSgfString:[request responseString]];
		onSuccess(game);
	}];
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
	int lastMoveNumber = 0; // DGS wants the move number this move is replying to
	NSURL *url = [self URLWithPath:@"/game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
	[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
	if ([comment length] > 0) {
		[request setPostValue:comment forKey:@"message"];
	}
	[request setPostValue:@"handicap" forKey:@"action"];
	
	NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([moves count] * 2)];

	for (Move *move in moves) {
		[moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
	}
	
	[request setPostValue:moveString forKey:@"stonestring"];
	[moveString release];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		onSuccess();
	}];
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
	// For the endgame, adding dead stones doesn't add moves to the SGF, so we 
	// don't subtract 1 from the moveNumber.
	int lastMoveNumber = moveNumber; 
	NSURL *url = [self URLWithPath:@"/game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
	[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
	[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];
	if ([comment length] > 0) {
		[request setPostValue:comment forKey:@"message"];
	}
	[request setPostValue:@"done" forKey:@"action"];
	
	if ([changedStones count] > 0) {
		NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([changedStones count] * 2)];
		
		for (Move *move in changedStones) {
			[moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
		}
		
		[request setPostValue:moveString forKey:@"stonestring"];
		[moveString release];
	}
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		onSuccess();
	}];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
	
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
		if ([comment length] > 0) {
			[request setPostValue:comment forKey:@"message"];
		}
		
		[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
			onSuccess();
		}];
		
	} else {
		// can't respond using quick_play.php
		int lastMoveNumber = moveNumber - 1; // DGS wants the move number this move is replying to
		NSURL *url = [self URLWithPath:@"/game.php"];
		
	    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"gid"];
		[request setPostValue:[NSString stringWithFormat:@"%d", lastMoveNumber] forKey:@"move"];
		[request setPostValue:@"Submit and go to status" forKey:@"nextstatus"];

		if ([comment length] > 0) {
			[request setPostValue:comment forKey:@"message"];
		}
		if ([move moveType] == kMoveTypePass) {
			[request setPostValue:@"pass" forKey:@"action"];
		} else if ([move moveType] == kMoveTypeResign) {
			[request setPostValue:@"resign" forKey:@"action"];
		} else if ([move moveType] == kMoveTypeMove) {
			[request setPostValue:@"domove" forKey:@"action"];
			[request setPostValue:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]] forKey:@"coord"];
		}
		
		[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
			onSuccess();
		}];
	}
}

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess {
	NSURL *url = [self URLWithPath:@"/add_to_waitingroom.php"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game numberOfGames]] forKey:@"nrGames"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game boardSize]] forKey:@"size"];
	[request setPostValue:[game komiTypeValue] forKey:@"handicap_type"];
	[request setPostValue:[game boolValue:[game stdHandicap]] forKey:@"stdhandicap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game timeValue]] forKey:@"timevalue"];
	[request setPostValue:[game timePeriodValue:[game timeUnit]] forKey:@"timeunit"];
	[request setPostValue:[game byoYomiTypeValue] forKey:@"byoyomitype"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimeValue]] forKey:@"byotimevalue_jap"];
	[request setPostValue:[game timePeriodValue:[game japaneseTimeUnit]] forKey:@"timeunit_jap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game japaneseTimePeriods]] forKey:@"byoperiods_jap"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimeValue]] forKey:@"byotimevalue_can"];
	[request setPostValue:[game timePeriodValue:[game canadianTimeUnit]] forKey:@"timeunit_can"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game canadianTimePeriods]] forKey:@"byoperiods_can"];
	[request setPostValue:[NSString stringWithFormat:@"%d", [game fischerTimeValue]] forKey:@"byotimevalue_fis"];
	[request setPostValue:[game timePeriodValue:[game fischerTimeUnit]] forKey:@"timeunit_fis"];
	
	[request setPostValue:[game boolValue:[game weekendClock]] forKey:@"weekendclock"];
	[request setPostValue:[game boolValue:[game rated]] forKey:@"rated"];
	[request setPostValue:[game minimumRating] forKey:@"rating1"];
	[request setPostValue:[game maximumRating] forKey:@"rating2"];
	[request setPostValue:[game comment] forKey:@"comment"];
	[request setPostValue:@"Add Game" forKey:@"add_game"];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request) {
		onSuccess();
	}];
}

#endif

#pragma mark -
#pragma mark Helper functions

// This takes the CSV data that the DGS API hands back to us and transforms
// it into a list of Game objects. 
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
			
			[game setSgfUrl:[self URLWithPath:[NSString stringWithFormat:@"/sgf.php?gid=%d&owned_comments=1&quick_mode=1", [game gameId]]]];
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

// Parses a list of games from the table on the 'status' page of 
// Dragon Go Server. This works, and provides a lot more information
// than quick_status's comma separated data. Unfortunately, the table 
// columns aren't marked in any consistent way I can find, so I either 
// have to use the ordering of the table cells (which the user can change)
// or the titles of the first row of table cells (which the user can change
// by changing their language). I haven't been able to figure out a way 
// around this, so this code sits here, unused -- for now.
- (NSArray *)gamesFromTable:(NSString *)htmlString {
	NSMutableArray *games = [NSMutableArray array];
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:htmlString options:CXMLDocumentTidyHTML error:&error];
	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='gameTable']/tr" error:&error];

    if ([tableRows count] >= 0) {
	
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
	}
	[doc release];
	return games;
}

// Parses a list of games from the waiting room. This uses the 
// markings on the 'th' row to guess which columns hold the data we're
// looking for. This may or may not be consistent, which is kinda rough,
// but we'll figure those problems out as we reach them.
- (NSArray *)gamesFromWaitingRoomTable:(NSString *)htmlString {
	NSMutableArray *games = [NSMutableArray array];
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:[htmlString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "] options:CXMLDocumentTidyHTML error:&error];
		
	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='waitingroomTable']/tr" error:&error];
    if ([tableRows count] > 0) {
        
        NSMutableArray *tableHeaders = nil;
        
        for (CXMLElement *row in tableRows) {
			
			// headers come first
			if (!tableHeaders) {
				NSArray *columns = [row nodesForXPath:@".//th" error:&error];
				if ([columns count] > 0) {
					tableHeaders = [NSMutableArray arrayWithCapacity:[columns count]];
					for (CXMLElement *column in columns) {
						[tableHeaders addObject:column];
					}
				} else {
					continue; // if we don't have table headers yet, keep searching for them
				}
			}
			
			if ([[[row attributeForName:@"id"] stringValue] isEqualToString:@"TableFilter"]) {
				continue;
			}

            NSArray *columns = [row nodesForXPath:@"td" error:&error];
            
            // bad things happen if these counts aren't equal
            if ([columns count] != [tableHeaders count]) {
                continue;
            }
			
            NewGame *game = [[NewGame alloc] init];
            
            for(int i = 0; i < [tableHeaders count]; i++) {
                CXMLElement *header = [tableHeaders objectAtIndex:i];
				CXMLNode *td = [columns objectAtIndex:i];
				
				if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col1"]) {
					NSString *data = [[[td nodesForXPath:@"a" error:&error] lastObject] stringValue];
                    game.opponent = data;
				} else if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col7"]) {
					game.boardSize = [[td stringValue] intValue];
				} else if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col3"]) {
					game.opponentRating = [[[[td nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col9"]) {
					game.time = [td stringValue];
				}
            }
            if ([game.opponent length] > 0) {
				[games addObject:game];				
			}
            [game release];
        }
	}
	[doc release];
	return games;
}

// Parses details from a waiting room game into a game object. 
// This will probably have issues with running in other languages that
// I'll have to figure out, and it's also kinda fragile, but I'm not
// sure I have any other options.
- (NewGame *)gamesFromWaitingRoomDetailTable:(NSString *)htmlString {
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:[htmlString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "] options:CXMLDocumentTidyHTML error:&error];
	NewGame *game;
	
	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='gameInfos']/tr" error:&error];
    if ([tableRows count] > 0) {
		game = [[[NewGame alloc] init] autorelease];
		
		for(int i = 0; i < [tableRows count]; i++) {
			NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];

			if (i == 2) {
				game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 3) {
				game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 4) {
				game.boardSize = [[[rowData lastObject] stringValue] intValue];
			} else if (i == 12) {
				game.comment = [[rowData lastObject] stringValue];
			} 
		}
	}
	[doc release];
	return game;
}

// This converts an integer row and column representing a board position and
// and returns a two-character string representing the coordinates that DGS
// uses. This can be passed directly to DGS to represent a board position.
- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize
{
	char rowChar = 'a' + (boardSize - row);
	char colChar = 'a' + (col - 1);
	return [NSString stringWithFormat:@"%c%c", colChar, rowChar];
}

- (void)dealloc {
    [super dealloc];
}

@end
