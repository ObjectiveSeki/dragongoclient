//
//  DGS.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "DGS.h"
#import "Player.h"
#import "DGSNetworkOperation.h"

@implementation DGS

const int kDefaultPageLimit = 20;

+ (id<GameServerProtocol>)sharedGameServer {
    static DGS *sharedGameServer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedGameServer = [[self alloc] init];
    });
    return sharedGameServer;
}

- (NSDictionary *)defaultCustomHeaderFields {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *headerFields = @{ @"X-client-identifier": @"Dragon Go Client iOS",
                                    @"X-bundle-identifier": infoDictionary[@"CFBundleIdentifier"],
                                    @"X-client-version": S(@"Version %@ (%@)", infoDictionary[@"CFBundleShortVersionString"], infoDictionary[@"CFBundleVersion"])};
    return headerFields;
}

- (id)initWithHostName:(NSString *)hostName apiPath:(NSString *)apiPath customHeaderFields:(NSDictionary *)headers {
    if (self = [super initWithHostName:hostName apiPath:apiPath customHeaderFields:headers]) {
        [self registerOperationSubclass:[DGSNetworkOperation class]];
    }
    return self;
}

- (id)init
{
    return [self initWithHostName:@"www.dragongoserver.net" apiPath:nil customHeaderFields:[self defaultCustomHeaderFields]];
}

#pragma mark -
#pragma mark Request handling

- (MKNetworkOperation *) operationWithPath:(NSString *)path
                                    params:(NSDictionary *)body
                                httpMethod:(NSString *)method
                                       ssl:(BOOL)useSSL {

    MKNetworkOperation *op = [super operationWithPath:path params:body httpMethod:method ssl:useSSL];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSLog(@"%@", completedOperation.url);
        NSLog(@"%@", completedOperation.responseString);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        NSLog(@"%@", completedOperation.url);
        NSLog(@"%@", completedOperation.responseString);
        DGSNetworkOperation *dgsOperation = (DGSNetworkOperation *)completedOperation;
        if (error.domain == kDGSErrorDomain && error.code == kDGSErrorCodeLoginError) {
            NSLog(@"Not logged in during request: %@", dgsOperation.readonlyRequest.URL);
            Player *oldPlayer = [Player currentPlayer];
            [self resetUserData];
            [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLogoutNotification object:oldPlayer];
        } else {
            [UIAlertView showWithError:error];
        }
    }];

    return op;
}

- (NSURL *)basePath {
    NSMutableString *url = [NSMutableString stringWithFormat:@"http://%@/", self.readonlyHostName];
    if (self.apiPath) {
        [url appendFormat:@"%@/", self.apiPath];
    }
    return [NSURL URLWithString:url];
}

- (NSArray *)cookiesForCurrentUser {
    return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self basePath]];
}

#pragma mark -
#pragma mark DGS Calls

- (NSOperation *)logout:(ErrorBlock)onError {
	static NSString *path = @"login.php?quick_mode=1&logout=1";
    MKNetworkOperation *op = [self operationWithPath:path];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        Player *oldPlayer = [Player currentPlayer];
        [self resetUserData];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLogoutNotification object:oldPlayer];
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)getCurrentPlayer:(ErrorBlock)onError {
    static NSString *path = @"quick_do.php?obj=user&cmd=info";

    MKNetworkOperation *op = [self operationWithPath:path];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [self setCurrentPlayerFromDictionary:completedOperation.responseJSON];
        [[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidLoginNotification object:nil];
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError
{
	static NSString *path = @"login.php?quick_mode=1";
    NSDictionary *params = @{
      @"userid": username,
      @"passwd": password
    };

    MKNetworkOperation *op = [self operationWithPath:path params:params httpMethod:@"POST"];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [self getCurrentPlayer:onError];
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)refreshCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    return [self getCurrentGames:onSuccess onError:onError];
}

- (NSOperation *)getCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
	static NSString *path = @"quick_status.php?no_cache=1&version=2";

    MKNetworkOperation *op = [self operationWithPath:path];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSOrderedSet *games = [self gamesFromCSV:completedOperation.responseString];
        MutableGameList *gameList = [[MutableGameList alloc] init];
        gameList.hasMorePages = NO;
        [gameList addGames:games];
		onSuccess(gameList);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    return [self getRunningGames:onSuccess onError:onError];
}

- (NSOperation *)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    NSString *pathFormat = @"quick_do.php?obj=game&cmd=list&view=running&with=user_id&lstyle=json&limit=%d&off=%d";
    GameList *gameList = [[GameList alloc] initWithPathFormat:pathFormat];
    
    // let's just return an empty list, and rely on the caller to fill it in
    // for us. These games might not be shown anyway.
    onSuccess(gameList);
    return nil; // not a real request
}

- (NSOperation *)getWaitingRoomGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    NSString *pathFormat = @"quick_do.php?obj=wroom&cmd=list&with=user_id&lstyle=json&limit=%d&off=%d";
    GameList *gameList = [[GameList alloc] initWithPathFormat:pathFormat];
    
    return [self addGamesToGameList:gameList onSuccess:onSuccess onError:onError];
}

- (NSOperation *)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    NSAssert(gameList, @"Can't add games to a nil gameList.");
    NSAssert(gameList.pathFormat, @"GameList: %@ is missing a path format.", gameList);
    NSString *path = [gameList pathForMoreGames:kDefaultPageLimit];

    MKNetworkOperation *op = [self operationWithPath:path];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSDictionary *gameListDictionary = completedOperation.responseJSON;
        NSMutableOrderedSet *games = [NSMutableOrderedSet orderedSetWithCapacity:[gameListDictionary[@"list_result"] count]];

        for (NSDictionary *gameDetails in gameListDictionary[@"list_result"]) {
            Game *game = [self parseGameFromDictionary:gameDetails ofType:gameListDictionary[@"list_object"]];
            [games addObject:game];
        }
        MutableGameList *mutableGameList = [gameList mutableCopy];

        [mutableGameList addGames:games];

        if ([gameListDictionary[@"list_has_next"] intValue] == 0) {
            mutableGameList.hasMorePages = NO;
        }
        mutableGameList.offset += [gameListDictionary[@"list_size"] intValue];

        onSuccess(mutableGameList);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess onError:(ErrorBlock)onError {
    static NSString *pathFormat = @"quick_do.php?obj=wroom&cmd=info&wrid=%d&with=user_id";
    MKNetworkOperation *op = [self operationWithPath:S(pathFormat, game.gameId)];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NewGame *gameDetails = [self gameFromWaitingRoomGameDictionary:completedOperation.responseJSON];
        onSuccess(gameDetails);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    static NSString *joinGameUrlFormat = @"quick_do.php?obj=wroom&cmd=join&wrid=%d";
    MKNetworkOperation *op = [self operationWithPath:S(joinGameUrlFormat, gameId)];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    static NSString *deleteGameUrlFormat = @"quick_do.php?obj=wroom&cmd=delete&wrid=%d";
    MKNetworkOperation *op = [self operationWithPath:S(deleteGameUrlFormat, gameId)];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess onError:(ErrorBlock)onError {
    static NSString *pathFormat = @"sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1";
    if (!game.sgfPath) {
        game.sgfPath = S(pathFormat, game.gameId);
    }
    
    MKNetworkOperation *op = [self operationWithPath:game.sgfPath];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [game setSgfString:completedOperation.responseString];
        onSuccess(game);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
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

    MKNetworkOperation *op = [self operationWithPath:urlString];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];

    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
	// For the endgame, adding dead stones doesn't add moves to the SGF, so we
	// don't subtract 1 from the moveNumber.
	int lastMoveNumber = moveNumber;
    static NSString *scoreUrlFormat = @"quick_do.php?obj=game&cmd=score&gid=%d&move_id=%d&move=%@&toggle=uniq";
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

    MKNetworkOperation *op = [self operationWithPath:urlString];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];

    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    int lastMoveNumber = moveNumber - 1; // DGS wants the move number this move is replying to
    static NSString *moveUrlFormat = @"quick_do.php?obj=game&cmd=move&gid=%d&move_id=%d&move=%@";
    static NSString *resignUrlFormat = @"quick_do.php?obj=game&cmd=resign&gid=%d&move_id=%d";
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


    MKNetworkOperation *op = [self operationWithPath:urlString];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];

    [self enqueueOperation:op];
    return op;
}

- (NSOperation *)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {

    static NSString *path = @"new_game.php";

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"nrGames"] = S(@"%d", game.numberOfGames);
    params[@"ruleset"] = game.ruleSetValue;
    params[@"size"] = S(@"%d", game.boardSize);
    params[@"cat_htype"] = game.komiTypeValue;
    params[@"color_m"] = game.manualKomiTypeValue;

    params[@"handicap_m"] = S(@"%d", game.handicap);
    params[@"komi_m"] = S(@"%0.1f", game.komi);
    params[@"adj_handicap"] = S(@"%d", game.adjustedHandicap);
    params[@"min_handicap"] = S(@"%d", game.minHandicap);
    params[@"max_handicap"] = S(@"%d", game.maxHandicap);
    params[@"stdhandicap"] = [game boolValue:game.stdHandicap];
    params[@"adj_komi"] = S(@"%f", game.adjustedKomi);
    params[@"jigo_mode"] = game.jigoModeValue;

    params[@"timevalue"] = S(@"%d", game.timeValue);
    params[@"timeunit"] = [game timePeriodValue:game.timeUnit];
    params[@"byoyomitype"] = game.byoYomiTypeValue;

    params[@"byotimevalue_jap"] = S(@"%d", game.japaneseTimeValue);
    params[@"timeunit_jap"] = [game timePeriodValue:game.japaneseTimeUnit];
    params[@"byoperiods_jap"] = S(@"%d", game.japaneseTimePeriods);

    params[@"byotimevalue_can"] = S(@"%d", game.canadianTimeValue);
    params[@"timeunit_can"] = [game timePeriodValue:game.canadianTimeUnit];
    params[@"byoperiods_can"] = S(@"%d", game.canadianTimePeriods);

    params[@"byotimevalue_fis"] = S(@"%d", game.fischerTimeValue);
    params[@"timeunit_fis"] = [game timePeriodValue:game.fischerTimeUnit];

    params[@"weekendclock"] = [game boolValue:game.weekendClock];
    params[@"rated"] = [game boolValue:game.rated];
    params[@"must_be_rated"] = [game boolValue:game.requireRatedOpponent];
    params[@"rating1"] = game.minimumRating;
    params[@"rating2"] = game.maximumRating;
    params[@"same_opp"] = S(@"%d", game.sameOpponent);
    params[@"comment"] = game.comment;

    params[@"add_game"] = @"Add Game";

    MKNetworkOperation *op = [self operationWithPath:path params:params httpMethod:@"POST"];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        onSuccess();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        onError(error);
    }];
    [self enqueueOperation:op];
    return op;
}

- (void)openGameInBrowser:(Game *)game {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:S(@"%@%@", [self basePath], game.webPath)]];
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

			game.sgfPath = S(@"sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1", game.gameId);
            game.webPath = S(@"game.php?gid=%d", game.gameId);
            
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
    player.handle = userDataDictionary[@"handle"];
    player.name = userDataDictionary[@"name"];
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
    game.sgfPath = S(@"sgf.php?gid=%d&owned_comments=1&quick_mode=1&no_cache=1", game.gameId);
    game.webPath = S(@"game.php?gid=%d", game.gameId);

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
