//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGS.h"
#import "GDataXMLNode.h"
#import "NewGame.h"
#import "Player.h"
#import "ASIFormDataRequest.h"
#import "IBAlertView.h"

@implementation DGS

static NSString * const DGSErrorDomain = @"DGSNetworkErrorDomain";

const int kDefaultPageLimit = 20;

+ (id<GameServerProtocol>)sharedGameServer {
    static DGS *sharedGameServer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedGameServer = [[self alloc] init];
    });
    return sharedGameServer;
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:@"http://www.dragongoserver.net"];
}

// This returns the base path onto which all of the urls used
// in this class refer. This is so that you can run your own
// DGS instance and play with it without ruining your own games.
- (NSURL *)URLWithPath:(NSString *)path {
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseURL], path]];
}

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
    BOOL invalidUser = (NSNotFound != [responseString rangeOfString:@"#Error: invalid_user"].location);
    BOOL unknownUser = (NSNotFound != [responseString rangeOfString:@"#Error: unknown_user"].location);
    BOOL noUserData = (nil == [Player currentPlayer] && (NSNotFound == [urlString rangeOfString:@"obj=user&cmd=info"].location) && (NSNotFound == [[[request originalURL] absoluteString] rangeOfString:@"login.php"].location));

	if (onErrorPageOrIndex || noUID || notLoggedIn || invalidUser || unknownUser || noUserData) {
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
		GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithHTMLString:responseString options:0 error:&error];
		NSArray *bodyElements = [doc nodesForXPath:@"//td[@id='pageBody']" error:&error];
		if ([bodyElements count] > 0) {
			errorString = [[bodyElements objectAtIndex:0] stringValue];
		}
	} else if (NSNotFound != [responseString rangeOfString:@"#Error:"].location) {
        NSString *errorKey;
        NSScanner *scanner = [[NSScanner alloc] initWithString:responseString];
        [scanner scanUpToString:@"[#Error:" intoString:NULL];
        [scanner scanString:@"[#Error: " intoString:NULL];
        [scanner scanUpToString:@";" intoString:&errorKey];
        
        errorString = NSLocalizedStringFromTable(errorKey, @"DGSErrors", nil);
    }

	return errorString;
}

// Called when the AlertView containing an error message is dismissed.
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.errorView = nil;
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
	NSLog(@"%@: %@", [request url], responseString);
	NSString *errorString = [self error:request responseString:responseString];

	if (NO == [self loggedIn:request responseString:responseString]) {
        // Login errors don't count as real errors
		NSLog(@"Not logged in during request: %@", [request url]);
        Player *oldPlayer = [Player currentPlayer];
        [self resetUserData];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLogoutNotification object:oldPlayer];
	} else if (errorString) {
        [self showErrorForRequest:request error:errorString];
	} else {
		ASIHTTPRequestBlock onSuccess = [[request userInfo] objectForKey:@"onSuccess"];

		if (onSuccess) {
			onSuccess(request, responseString);
		}
	}
}

- (void)showErrorForRequest:(ASIHTTPRequest *)request error:(NSString *)errorString {
    NSLog(@"Error during request: %@\n  Error: %@", [request url], errorString);
    [IBAlertView showAlertWithTitle:@"Error" message:errorString dismissTitle:@"OK" dismissBlock:^() {
        ErrorBlock onError = request.userInfo[@"onError"];
        
        if (onError) {
            NSError *error = [[NSError alloc] initWithDomain:DGSErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: errorString }];
            onError(error);
        }
    }];
}

// Called when a request fails entirely.
- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self showErrorForRequest:request error:@"There was a problem communicating with the server."];
}

// Starts an asynchronous request, calling onSuccess when the request finishes.
- (void)performRequest:(ASIHTTPRequest *)request onSuccess:(ASIHTTPRequestBlock)onSuccess onError:(ErrorBlock)onError {
	NSLog(@"Performing request: %@", [request url]);

	NSMutableDictionary *userInfo = [request.userInfo mutableCopy];

	if (!userInfo) {
		userInfo = [[NSMutableDictionary alloc] init];
	}

	if (onSuccess) {
        userInfo[@"onSuccess"] = [onSuccess copy];
	}
    
    if (onError) {
        userInfo[@"onError"] = [onError copy];
    }

	request.userInfo = userInfo;

	request.delegate = self;
	[request startAsynchronous];
}

- (id)objectFromJSONData:(NSData *)data {
    NSError *parseError;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
    if (parseError) {
        NSLog(@"Error reading json: %@", [parseError localizedDescription]);
    }
    return object;
}

#pragma mark -
#pragma mark DGS Calls


- (void)logout:(ErrorBlock)onError {
	NSURL *url = [self URLWithPath:@"/login.php?quick_mode=1&logout=1"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        Player *oldPlayer = [Player currentPlayer];
        [self resetUserData];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLogoutNotification object:oldPlayer];
    } onError:onError];
}

- (void)getCurrentPlayer:(ErrorBlock)onError {
    NSURL *url = [self URLWithPath:@"/quick_do.php?obj=user&cmd=info"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
    [self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        [self setCurrentPlayerFromDictionary:[self objectFromJSONData:[request responseData]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLoginNotification object:nil];
    } onError:onError];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError
{
	NSURL *url = [self URLWithPath:@"/login.php?quick_mode=1"];

	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:username forKey:@"userid"];
	[request setPostValue:password forKey:@"passwd"];
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString){
        [self getCurrentPlayer:onError];
        onSuccess();
    } onError:onError];
}

- (NSArray *)cookiesForCurrentUser {
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self baseURL]];
}

- (void)refreshCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self getCurrentGames:onSuccess onError:onError];
}

- (void)getCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
	NSURL *url = [self URLWithPath:@"/quick_status.php?no_cache=1&version=2"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		NSOrderedSet *games = [self gamesFromCSV:responseString];
        GameList *gameList = [[GameList alloc] init];
        gameList.hasMorePages = NO;
        [gameList addGames:games];
		onSuccess(gameList);
	} onError:onError];
}

- (void)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self getRunningGames:onSuccess onError:onError];
}

// http://www.dragongoserver.net/quick_do.php?obj=game&cmd=list&view=running&lstyle=json
// {"version":"1.0.15:3","error":"","quota_count":495,"quota_expire":"2012-12-21 08:51:17","list_object":"game","list_totals":"1","list_size":1,"list_offset":0,"list_limit":10,"list_has_next":0,"list_order":"time_lastmove-,id-","list_result":[{"id":765115,"double_id":0,"tournament_id":0,"game_action":2,"status":"PLAY","flags":"","score":"","game_type":"GO","rated":1,"ruleset":"JAPANESE","size":19,"komi":0.5,"jigo_mode":"KEEP_KOMI","handicap":0,"handicap_mode":"STD","shape_id":0,"time_started":"2012-10-20 01:55:50","time_lastmove":"2012-12-13 12:59:31","time_weekend_clock":1,"time_mode":"FIS","time_limit":"F: 7d + 1d","my_id":53292,"move_id":105,"move_count":105,"move_color":"W","move_uid":53292,"move_opp":46277,"move_last":"cg","prio":0,"black_user":{"id":46277},"black_gameinfo":{"prisoners":0,"remtime":"F: 7d (+ 1d)","rating_start":"15k (-11%)","rating_start_elo":"588.67412133587"},"white_user":{"id":53292},"white_gameinfo":{"prisoners":1,"remtime":"F: 5d (+ 1d)","rating_start":"14k (-5%)","rating_start_elo":"695.01316811253"}}]}
- (void)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    GameList *gameList = [[GameList alloc] init];
    gameList.pathFormat = @"/quick_do.php?obj=game&cmd=list&view=running&with=user_id&lstyle=json&limit=%d&off=%d";
    // let's just return an empty list, and rely on the caller to fill it in
    // for us. These games might not be shown anyway.
    onSuccess(gameList);
}

- (void)getWaitingRoomGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    GameList *gameList = [[GameList alloc] init];
    gameList.pathFormat = @"/quick_do.php?obj=wroom&cmd=list&with=user_id&lstyle=json&limit=%d&off=%d";
    [self addGamesToGameList:gameList onSuccess:onSuccess onError:onError];
}

- (void)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    assert(gameList);
    assert(gameList.pathFormat);
    NSURL *url = [self URLWithPath:[gameList pathForMoreGames:kDefaultPageLimit]];
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];
    
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        NSDictionary *gameListDictionary = [self objectFromJSONData:[request responseData]];
        NSMutableOrderedSet *games = [NSMutableOrderedSet orderedSetWithCapacity:[gameListDictionary[@"list_result"] count]];
        
        for (NSDictionary *gameDetails in gameListDictionary[@"list_result"]) {
            Game *game = [self parseGameFromDictionary:gameDetails ofType:gameListDictionary[@"list_object"]];
            [games addObject:game];
        }
        
        [gameList addGames:games];
        
        if ([gameListDictionary[@"list_has_next"] intValue] == 0) {
            gameList.hasMorePages = NO;
        }
        gameList.offset += [gameListDictionary[@"list_size"] intValue];
        
        onSuccess(gameList);
	} onError:onError];
}

- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess onError:(ErrorBlock)onError {
	NSURL *url = [self URLWithPath:[NSString stringWithFormat:@"/quick_do.php?obj=wroom&cmd=info&wrid=%d&with=user_id", game.gameId]];

	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setCachePolicy:ASIDoNotReadFromCacheCachePolicy];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        NewGame *gameDetails = [self gameFromWaitingRoomGameDictionary:[self objectFromJSONData:[request responseData]]];
        onSuccess(gameDetails);
	} onError:onError];
}

- (void)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    static NSString *joinGameUrlFormat = @"/quick_do.php?obj=wroom&cmd=join&wrid=%d";
	NSURL *url = [self URLWithPath:[NSString stringWithFormat:joinGameUrlFormat, gameId]];

	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:onError];
}

- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    static NSString *deleteGameUrlFormat = @"/quick_do.php?obj=wroom&cmd=delete&wrid=%d";
	NSURL *url = [self URLWithPath:[NSString stringWithFormat:deleteGameUrlFormat, gameId]];
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:onError];
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess onError:(ErrorBlock)onError {
    if (game.sgfUrl == nil) {
        [game setSgfUrl:[self URLWithPath:[NSString stringWithFormat:@"/sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1", [game gameId]]]];
    }

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:game.sgfUrl];
    [self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        [game setSgfString:responseString];
        onSuccess(game);
    } onError:onError];
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    static NSString *playHandicapStonesFormat = @"quick_do.php?obj=game&cmd=set_handicap&gid=%d&move_id=%d&move=%@";
	int lastMoveNumber = 0; // DGS wants the move number this move is replying to
    NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([moves count] * 2)];
    
	for (Move *move in moves) {
		[moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
	}
        
    NSMutableString *urlString = [NSMutableString stringWithFormat:playHandicapStonesFormat, game.gameId, lastMoveNumber, moveString];

	if ([comment length] > 0) {
		[urlString appendString:[NSString stringWithFormat:@"&msg=%@", [comment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	
    NSURL *url = [self URLWithPath:urlString];
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:onError];
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
	// For the endgame, adding dead stones doesn't add moves to the SGF, so we
	// don't subtract 1 from the moveNumber.
	int lastMoveNumber = moveNumber;
    static NSString *scoreUrlFormat = @"/quick_do.php?obj=game&cmd=score&gid=%d&move_id=%d&move=%@";
    NSMutableString *moveString = [[NSMutableString alloc] initWithCapacity:([changedStones count] * 2)];
    NSMutableString *urlString;
    
    for (Move *move in changedStones) {
        [moveString appendString:[self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
    }
    
    urlString = [NSMutableString stringWithFormat:scoreUrlFormat, game.gameId, lastMoveNumber, moveString];
        
    if ([comment length] > 0) {
        [urlString appendString:[NSString stringWithFormat:@"&msg=%@", [comment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }
    
    if ([changedStones count] == 0) {
        [urlString appendString:@"&agree=1"];
    }
        
    NSURL *url = [self URLWithPath:urlString];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:onError];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    int lastMoveNumber = moveNumber - 1; // DGS wants the move number this move is replying to
    static NSString *moveUrlFormat = @"/quick_do.php?obj=game&cmd=move&gid=%d&move_id=%d&move=%@";
    static NSString *resignUrlFormat = @"/quick_do.php?obj=game&cmd=resign&gid=%d&move_id=%d";
    NSMutableString *urlString;
    
    if ([move moveType] == kMoveTypePass) {
        urlString = [NSMutableString stringWithFormat:moveUrlFormat, game.gameId, lastMoveNumber, @"pass"];
    } else if ([move moveType] == kMoveTypeResign) {
        urlString = [NSMutableString stringWithFormat:resignUrlFormat, game.gameId, lastMoveNumber];
    } else if ([move moveType] == kMoveTypeMove) {
        urlString = [NSMutableString stringWithFormat:moveUrlFormat, game.gameId, lastMoveNumber, [self sgfCoordsWithRow:[move row] column:[move col] boardSize:[move boardSize]]];
    } 
    
    if ([comment length] > 0) {
		[urlString appendString:[NSString stringWithFormat:@"&msg=%@", [comment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
    
    NSURL *url = [self URLWithPath:urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
        onSuccess();
    } onError:onError];
}

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    NSURL *url = [self URLWithPath:@"/new_game.php"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

    [request setPostValue:[NSString stringWithFormat:@"%d", [game numberOfGames]] forKey:@"nrGames"];
    [request setPostValue:[game ruleSetValue] forKey:@"ruleset"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game boardSize]] forKey:@"size"];
    [request setPostValue:[game komiTypeValue] forKey:@"cat_htype"];
    [request setPostValue:[game manualKomiTypeValue] forKey:@"color_m"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game handicap]] forKey:@"handicap_m"];
    [request setPostValue:[NSString stringWithFormat:@"%0.1f", [game komi]] forKey:@"komi_m"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game adjustedHandicap]] forKey:@"adj_handicap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game minHandicap]] forKey:@"min_handicap"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game maxHandicap]] forKey:@"max_handicap"];
    [request setPostValue:[game boolValue:[game stdHandicap]] forKey:@"stdhandicap"];
    [request setPostValue:[NSString stringWithFormat:@"%f", [game adjustedKomi]] forKey:@"adj_komi"];
    [request setPostValue:[game jigoModeValue] forKey:@"jigo_mode"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game timeValue]] forKey:@"timevalue"];
    [request setPostValue:[game timePeriodValue:[game timeUnit]] forKey:@"timeunit"];
    [request setPostValue:[game byoYomiTypeValue] forKey:@"byoyomitype"];
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
    [request setPostValue:[game boolValue:[game requireRatedOpponent]] forKey:@"must_be_rated"];
    [request setPostValue:[game minimumRating] forKey:@"rating1"];
    [request setPostValue:[game maximumRating] forKey:@"rating2"];
    [request setPostValue:[NSString stringWithFormat:@"%d", [game sameOpponent]] forKey:@"same_opp"];
    [request setPostValue:[game comment] forKey:@"comment"];
    [request setPostValue:@"Add Game" forKey:@"add_game"];

	[self performRequest:request onSuccess:^(ASIHTTPRequest *request, NSString *responseString) {
		onSuccess();
	} onError:onError];
}

#pragma mark -
#pragma mark Helper functions

// This takes the CSV data that the DGS API hands back to us and transforms
// it into a list of Game objects.
- (NSOrderedSet *)gamesFromCSV:(NSString *)csvData {
	NSArray *lines = [csvData componentsSeparatedByString:@"\n"];
    NSMutableOrderedSet *games = [NSMutableOrderedSet orderedSetWithCapacity:[lines count]];
    
	for(NSString *line in lines) {
		NSArray *cols = [line componentsSeparatedByString:@","];
		if([cols[0] isEqual:@"G"]) {
			Game *game = [[Game alloc] init];
			[game setGameId:[cols[1] intValue]];
			NSString *opponentString = cols[2];
			[game setOpponent:[opponentString substringWithRange:NSMakeRange(1, [opponentString length] - 2)]];

			[game setSgfUrl:[self URLWithPath:[NSString stringWithFormat:@"/sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1", [game gameId]]]];
			if ([cols[3] isEqual:@"W"]) {
				[game setColor:kMovePlayerWhite];
			} else {
				[game setColor:kMovePlayerBlack];
			}

			NSString *lastMoveString = cols[4];
			[game setLastMove:[lastMoveString substringWithRange:NSMakeRange(1, [lastMoveString length] - 2)]];

			NSString *timeRemainingString = cols[5];
			[game setTime:[timeRemainingString substringWithRange:NSMakeRange(1, [timeRemainingString length] - 2)]];
            
            game.moveId = [cols[8] intValue];
            game.myTurn = YES; // Games from the status API are always my turn

			[games addObject:game];
		}
	}
	return games;
}

- (void)setCurrentPlayerFromDictionary:(NSDictionary *)userDataDictionary {
    Player *player = [[Player alloc] init];
    player.userId = userDataDictionary[@"id"];
    player.ratingStatus = userDataDictionary[@"rating_status"];
    [Player setCurrentPlayer:player];
}

- (void)resetUserData {
    [Player setCurrentPlayer:nil];
}

- (Game *)gameFromGameDictionary:(NSDictionary *)gameDictionary {
    Game *game = [[Game alloc] init];
    int myId = [gameDictionary[@"my_id"] intValue];
    game.gameId = [gameDictionary[@"id"] intValue];
    NSString *sgfUrl = S(@"/sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1", game.gameId);
    game.sgfUrl = [self URLWithPath:sgfUrl];
    
    if ([gameDictionary[@"white_user"][@"id"] intValue] == myId) {
        game.color = kMovePlayerWhite;
        game.time = gameDictionary[@"white_gameinfo"][@"remtime"];
        game.opponent = gameDictionary[@"black_user"][@"handle"];
    } else {
        game.color = kMovePlayerBlack;
        game.time = gameDictionary[@"black_gameinfo"][@"remtime"];
        game.opponent = gameDictionary[@"white_user"][@"handle"];
    }
    
    if ((game.color == kMovePlayerBlack && [gameDictionary[@"move_color"] isEqualToString:@"B"]) ||
        (game.color == kMovePlayerWhite && [gameDictionary[@"move_color"] isEqualToString:@"W"])) {
        game.myTurn = YES;
    } else {
        game.myTurn = NO;
    }
    
    game.lastMove = gameDictionary[@"move_last"];
    game.moveId = [gameDictionary[@"move_id"] intValue];
    return game;
}

- (NewGame *)gameFromWaitingRoomGameDictionary:(NSDictionary *)gameDictionary {
    
    NewGame *game = [[NewGame alloc] init];

    game.gameId = [gameDictionary[@"id"] intValue];
    game.opponent = gameDictionary[@"user"][@"name"];
    game.opponentRating = gameDictionary[@"user"][@"rating"];
    game.boardSize = [gameDictionary[@"size"] intValue];
    game.komiTypeName = [game komiTypeNameFromValue:gameDictionary[@"handicap_type"]];
    game.handicap = [gameDictionary[@"handicap"] intValue];
    game.komi = [gameDictionary[@"komi"] floatValue];
    game.ratedString = [game boolNameFromValue:[gameDictionary[@"rated"] boolValue]];
    game.weekendClockString = [game boolNameFromValue:[gameDictionary[@"time_weekend_clock"] boolValue]];
    game.time = gameDictionary[@"time_limit"];
    game.comment = gameDictionary[@"comment"];
    game.myGame = ([[Player currentPlayer].userId isEqual:gameDictionary[@"user"][@"id"]]);

    return game;
}

- (Game *)parseGameFromDictionary:(NSDictionary *)dictionary ofType:(NSString *)gameType {
    if ([gameType isEqualToString:@"wroom"]) {
        return [self gameFromWaitingRoomGameDictionary:dictionary];
    } else if ([gameType isEqualToString:@"game"]) {
        return [self gameFromGameDictionary:dictionary];
    }
    return nil;
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


@end
