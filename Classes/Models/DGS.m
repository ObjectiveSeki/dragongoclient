//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "/usr/include/sqlite3.h"

#import "DGS.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"
#import "NewGame.h"

#ifndef LOGIC_TEST_MODE
#import "ASIFormDataRequest.h"
#import "DGSPhoneAppDelegate.h"
#endif


@implementation DGS

@synthesize delegate;

#ifndef LOGIC_TEST_MODE
@synthesize errorView;
#endif

// This returns the base path onto which all of the urls used 
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
//
// WARNING: the current CVS checkout of DGS differs significantly
// from the running version -- therefore, you may run into bugs when
// switching back to the real server.
- (NSURL *)URLWithPath:(NSString *)path {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://www.dragongoserver.net", path]];
}

#ifndef LOGIC_TEST_MODE

- (id)init {
	if (self = [super init]) {
		 [ASIHTTPRequest setDefaultTimeOutSeconds:15];
	}
	return self;
}

#pragma mark -
#pragma mark Request handling

// Is the user currently logged in through their cookie? YES if so,
// NO if not. 
- (BOOL)loggedIn:(ASIHTTPRequest *)request responseString:(NSString *)responseString {
	NSString *urlString = [[request url] absoluteString];
	
	// Use a simple heuristic here. If we are hitting a normal HTML page, we
	// can figure out if the user is logged in by checking if we ended up on index.php
	// or error.php (in the case where the error is not_logged_in)
	BOOL onErrorPageOrIndex = (NSNotFound != [urlString rangeOfString:@"error.php?err=not_logged_in"].location || NSNotFound != [urlString rangeOfString:@"index.php"].location);
	
	// If we're using the DGS api, it will return the string 'Error: no_uid' or 'Error: not_logged_in' if we aren't logged in.
	BOOL noUID = (NSNotFound != [responseString rangeOfString:@"#Error: no_uid"].location);
	BOOL notLoggedIn = (NSNotFound != [responseString rangeOfString:@"#Error: not_logged_in"].location);
	
	if (onErrorPageOrIndex || noUID || notLoggedIn ) {
		return NO;
	}
	return YES;
}

// Checks the request body to see if it contains an error. If so,
// return the error string. Otherwise, returns nil.
- (NSString *)error:(ASIHTTPRequest *)request responseString:(NSString *)responseString {
	NSString *urlString = [[request url] absoluteString];
	NSString *errorString = nil;
	
	if (NSNotFound != [urlString rangeOfString:@"error.php"].location) {
		NSError *error;
		CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:responseString options:CXMLDocumentTidyHTML error:&error];
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
    self.errorView = nil;
	[[self delegate] requestCancelled];
}

- (NSString *)lossyStringFromData:(NSData *)data encoding:(NSStringEncoding)encoding replaceString:(NSString *)replacement {
	NSMutableString *output = [NSMutableString stringWithCapacity:[data length]];
	int pos = 0;
	int lookahead = 1;
	while (pos + lookahead <= [data length]) {
		NSRange currentRange = NSMakeRange(pos, lookahead);
		NSData *possibleChar = [data subdataWithRange:currentRange];
		NSString *str = [[NSString alloc] initWithData:possibleChar encoding:encoding];
		if (str) {
			[output appendString:str];
            [str release];
			pos += lookahead;
			lookahead = 1;
		} else {
			lookahead += 1;
			if (lookahead > 4) {
				[output appendString:replacement];
				// skip to the next possible char
				lookahead = 1;
				pos += 1;
			}
		}
	}
	return output;
}

// Called when an ASIHTTPRequest finishes. Handles being logged out, 
// error messages, and successes. 
- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSString *responseString = [request responseString];
	if (!responseString) {
		// If there are invalid characters in the encoding we're given, 
		// [request responseString] returns nil. We still want to get the 
		// data that's valid out of the page, though, and Apple doesn't
		// expose that functionality publicly. So instead, we'll call my 
		// brain-dead dumb slow function to extract as much data as we can. 
		// Hopefully it's not too bad.
		responseString = [self lossyStringFromData:[request responseData] encoding:[request responseEncoding] replaceString:@"?"];
	}
	JWLog(@"%@: %@", [request url], responseString);
	NSString *errorString = [self error:request responseString:responseString];
	
	if (errorString) {
		JWLog(@"Error during request: %@\n  Error: %@", [request url], errorString);
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		self.errorView = alertView;
        [alertView release];
        [self.errorView show];
	} else if (NO == [self loggedIn:request responseString:responseString]) {
		JWLog(@"Not logged in during request: %@", [request url]);
		[[self delegate] notLoggedIn];
	} else {
		ASIHTTPRequestBlock onSuccess = [[request userInfo] objectForKey:@"onSuccess"];
		
		if (onSuccess) {
			onSuccess(request, responseString);
		}
	}
}

// Called when a request fails entirely.
- (void)requestFailed:(ASIHTTPRequest *)request
{
	JWLog(@"Request failed: %@", [request url]);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"There was a problem communicating with the server." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	self.errorView = alertView;
    [alertView release];
    [self.errorView show];
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
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		[self.delegate loggedIn];
	}];
}

- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess {
	NSURL *url = [self URLWithPath:@"/quick_status.php"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		NSArray *gameList = [self gamesFromCSV:responseString];
		onSuccess(gameList);
	}];
}

- (void)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess {
    GameList *gameList = [[[GameList alloc] initWithPageLoader:^(GameList *gameList, NSString *pagePath, void (^onSuccess)()) {
        NSURL *url = [self URLWithPath:pagePath];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
        
        [self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
            [gameList appendGames:[self gamesFromWaitingRoomTable:responseString]];
            gameList.nextPagePath = [self nextPagePath:responseString];
            onSuccess();
        }];
    }] autorelease];
    
    // add=9 to force the time limit to show up
    gameList.nextPagePath = @"/waiting_room.php?add=9";
    
    [gameList loadNextPage:^(GameList *gameList) {
        onSuccess(gameList);
    }];
}

- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:game.detailUrl];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		NewGame *gameDetails = [self gameFromWaitingRoomDetailTable:responseString game:game];
		onSuccess(gameDetails);
	}];
}

- (void)joinWaitingRoomGame:(int)gameId comment:(NSString *)comment onSuccess:(void (^)())onSuccess {
	
	NSURL *url = [self URLWithPath:@"/join_waitingroom_game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"id"];
	[request setPostValue:comment forKey:@"reply"];
	[request setPostValue:@"Join" forKey:@"join"];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	}];
}

- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess {
	
	NSURL *url = [self URLWithPath:@"/join_waitingroom_game.php"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:[NSString stringWithFormat:@"%d", gameId] forKey:@"id"];
	[request setPostValue:@"t" forKey:@"delete"];
	[request setPostValue:@"Delete" forKey:@"deletebut"];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	}];
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess {
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:game.sgfUrl];
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		[game setSgfString:responseString];
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

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
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
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
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
		
		[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
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
		
		[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
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
    [request setPostValue:[game boolValue:[game requireRatedOpponent]] forKey:@"must_be_rated"];
	[request setPostValue:[game minimumRating] forKey:@"rating1"];
	[request setPostValue:[game maximumRating] forKey:@"rating2"];
	[request setPostValue:[game comment] forKey:@"comment"];
	[request setPostValue:@"Add Game" forKey:@"add_game"];
	
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
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
            
#ifndef LOGIC_TEST_MODE
            sqlite3 *database = [DGSAppDelegate database];
            {
                static sqlite3_stmt *insertGameStmt = nil;
                if (insertGameStmt == nil) {
                    if (sqlite3_prepare_v2(database, "INSERT INTO games (id, finished, ourturn, opponent, sgf, ourcolor, timeleft) VALUES (?, 0, 0, '', '', '', '')", -1, &insertGameStmt, NULL) != SQLITE_OK) {
                        JWLog("error create insert games statement '%s'", sqlite3_errmsg(database));
                    }
                }
                // try inserting assuming it's a new game
                sqlite3_bind_int(insertGameStmt, 1, [game gameId]);
                if (sqlite3_step(insertGameStmt) == SQLITE_DONE) {
                    JWLog("inserted new game %d", [game gameId]);
                } else {
                    // this isn't normally a problem. just means that this game already exists in the db.
                    JWLog("failed to insert game %d '%s'", [game gameId], sqlite3_errmsg(database));
                }
                sqlite3_reset(insertGameStmt);

                // update the game information
                static sqlite3_stmt *updateGameStmt = nil;
                if (updateGameStmt == nil) {
                    if (sqlite3_prepare_v2(database, "UPDATE games SET ourturn = 1, opponent = ?, ourcolor = ?, timeleft = ? WHERE id = ?", -1, &updateGameStmt, NULL) != SQLITE_OK) {
                        JWLog("error create insert games statement '%s'", sqlite3_errmsg(database));
                    }
                }
                sqlite3_bind_text(updateGameStmt, 1, [game getOpponent], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(updateGameStmt, 2, [game color]);
                sqlite3_bind_text(updateGameStmt, 3, [[game time] UTF8String], -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(updateGameStmt, 4, [game gameId]);
                if (sqlite3_step(updateGameStmt) == SQLITE_DONE) {
                    JWLog("updated game %d", [game gameId]);
                } else {
                    JWLog("failed to update game %d '%s'", [game gameId], sqlite3_errmsg(database));
                }
                sqlite3_reset(updateGameStmt);
            }
#endif
			
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

    if ([tableRows count] > 0) {
	
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
				if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col0"] || 
					[[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col17"]) {
					CXMLElement *link = [[td nodesForXPath:@"a" error:&error] lastObject];
					NSString *href = [[link attributeForName:@"href"] stringValue];
					game.detailUrl = [self URLWithPath:[NSString stringWithFormat:@"/%@", href]];
					NSArray *keyValues = [[[href componentsSeparatedByString:@"?"] lastObject] componentsSeparatedByString:@"&"];
 					for (NSString *keyValue in keyValues) {
						NSArray *keyValuePair = [keyValue componentsSeparatedByString:@"="];
						if ([[keyValuePair objectAtIndex:0] isEqualToString:@"info"]) {
							game.gameId = [[keyValuePair lastObject] intValue];
						}
					}
				} else if ([[[header attributeForName:@"id"] stringValue] isEqualToString:@"Col1"]) {
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
                           
// Tells us whether there are more pages in the table we're looking at
- (NSString *)nextPagePath:(NSString *)htmlString {
    NSString *nextPagePath = nil;
    NSError *error;
    CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:[htmlString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "] options:CXMLDocumentTidyHTML error:&error];
    NSArray *nextPageIndicator = [doc nodesForXPath:@"//td[@class='PagingL']//a[img[@src='images/next.gif']]/@href" error:&error];
    if ([nextPageIndicator count] != 0) {
        nextPagePath = [NSString stringWithFormat:@"/%@", [[nextPageIndicator lastObject] stringValue]];
    }
    [doc release];
    return nextPagePath;
}
                           
// The newer versions of DGS have these items in a different order.
- (NewGame *)gameFromNewWaitingRoomDetailTable:(NSArray *)tableRows game:(NewGame *)game {
	NSError *error;
	// There are different row counts depending on if it's an even game or a
	// conventional/proper handicap game. We have to parse the rows differently 
	// depending on what type of game it is.
	if ([tableRows count] == 16) { // Even game
		for(int i = 0; i < [tableRows count]; i++) {
			NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];
			
			if (i == 2) {
				game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 3) {
				game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 5) {
				game.boardSize = [[[rowData lastObject] stringValue] intValue];
			} else if (i == 6) {
				game.komiTypeName = [[rowData lastObject] stringValue];
			} else if (i == 8) {
				game.handicap = [[[rowData lastObject] stringValue] intValue];
			} else if (i == 9) {
				game.komi = [[[rowData lastObject] stringValue] floatValue];
			} else if (i == 13) {
				game.ratedString = [[rowData lastObject] stringValue];
			} else if (i == 14) {
				game.weekendClockString = [[rowData lastObject] stringValue];
			} else if (i == 15) {
				game.comment = [[rowData lastObject] stringValue];
			} 
		}			
	} else if ([tableRows count] == 17 || [tableRows count] == 13) { // Handicap game
		for(int i = 0; i < [tableRows count]; i++) {
			NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];
			
			if (i == 2) {
				game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 3) {
				game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			} else if (i == 5) {
				game.boardSize = [[[rowData lastObject] stringValue] intValue];
			} else if (i == 6) {
				game.komiTypeName = [[rowData lastObject] stringValue];
			} else if (i == 10) {
				game.ratedString = [[rowData lastObject] stringValue];
			} else if (i == 11) {
				game.weekendClockString = [[rowData lastObject] stringValue];
			} else if (i == 12) {
				game.comment = [[rowData lastObject] stringValue];
			} else if (i == 16) {
				game.komi = [[[rowData lastObject] stringValue] floatValue];
			}  
		}
	}
	return game;
}

// Parses details from a waiting room game into a game object. 
// This will probably have issues with running in other languages that
// I'll have to figure out, and it's also kinda fragile, but I'm not
// sure I have any other options.
- (NewGame *)gameFromWaitingRoomDetailTable:(NSString *)htmlString game:(NewGame *)game {
	NSError *error;
	CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:[htmlString stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "] options:CXMLDocumentTidyHTML error:&error];

	NSArray *tableRows = [doc nodesForXPath:@"//table[@id='gameInfos']/tr" error:&error];
    if ([tableRows count] > 0) {
		
		// There are different row counts depending on if it's an even game or a
		// conventional/proper handicap game. We have to parse the rows differently 
		// depending on what type of game it is.
		if ([tableRows count] == 14) { // Even game
			for(int i = 0; i < [tableRows count]; i++) {
				NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];
				
				if (i == 2) {
					game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 3) {
					game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 4) {
					game.boardSize = [[[rowData lastObject] stringValue] intValue];
				} else if (i == 5) {
					game.komiTypeName = [[rowData lastObject] stringValue];
				} else if (i == 6) {				
					game.komi = [[[rowData lastObject] stringValue] floatValue];
				} else if (i == 11) {
					game.ratedString = [[rowData lastObject] stringValue];
				} else if (i == 12) {
					game.weekendClockString = [[rowData lastObject] stringValue];
				} else if (i == 13) {
					game.comment = [[rowData lastObject] stringValue];
				} 
			}			
		} if ([tableRows count] == 15) { // Double game
			for(int i = 0; i < [tableRows count]; i++) {
				NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];
				
				if (i == 2) {
					game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 3) {
					game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 4) {
					game.boardSize = [[[rowData lastObject] stringValue] intValue];
				} else if (i == 5) {
					game.komiTypeName = [[rowData lastObject] stringValue];
				} else if (i == 6) {
                    game.handicap = [[[rowData lastObject] stringValue] intValue];
                } else if (i == 7) {				
					game.komi = [[[rowData lastObject] stringValue] floatValue];
				} else if (i == 12) {
					game.ratedString = [[rowData lastObject] stringValue];
				} else if (i == 13) {
					game.weekendClockString = [[rowData lastObject] stringValue];
				} else if (i == 14) {
					game.comment = [[rowData lastObject] stringValue];
				} 
			}			
		} else if ([tableRows count] == 17 || [tableRows count] == 13) { // Handicap game
			for(int i = 0; i < [tableRows count]; i++) {
				NSArray *rowData = [[tableRows objectAtIndex:i] nodesForXPath:@"td" error:&error];
				
				if (i == 2) {
					game.opponent = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 3) {
					game.opponentRating = [[[[[rowData lastObject] nodesForXPath:@"a" error:&error] lastObject] stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				} else if (i == 4) {
					game.boardSize = [[[rowData lastObject] stringValue] intValue];
				} else if (i == 5) {
					game.komiTypeName = [[rowData lastObject] stringValue];
				} else if (i == 10) {
					game.ratedString = [[rowData lastObject] stringValue];
				} else if (i == 11) {
					game.weekendClockString = [[rowData lastObject] stringValue];
				} else if (i == 12) {
					game.comment = [[rowData lastObject] stringValue];
				} else if (i == 16) {
					game.komi = [[[rowData lastObject] stringValue] floatValue];
				}  
			}
		}
	} else {
		tableRows = [doc nodesForXPath:@"//table[@id='gameTableInfos']/tr" error:&error];
		if ([tableRows count] > 0) {
			game = [self gameFromNewWaitingRoomDetailTable:tableRows game:game];
		}
	}
	
	NSArray *joinButton = [doc nodesForXPath:@"//td/input[@name='join']" error:&error];
	if ([joinButton count] > 0) {
		game.myGame = false;
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
#ifndef LOGIC_TEST_MODE
    self.errorView = nil;
#endif
    [super dealloc];
}

@end
