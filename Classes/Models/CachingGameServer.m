//
//  CachingGameServer.m
//  DGSPhone
//
//  Most of this code was provided by adam miller. I just moved it around.
//

#import "CachingGameServer.h"
#import "sqlite3.h"

@implementation CachingGameServer

static sqlite3 *database;

@synthesize gameServer;

- (id)initWithGameServer:(id<GameServerProtocol>)aGameServer;
{
    self = [super init];
    if (self) {
        self.gameServer = aGameServer;
    }
    return self;
}

- (void)dealloc {
    self.gameServer = nil;
    [super dealloc];
}

+ (void)checkAndCreateDatabase {
	// Check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
    
	NSString *databaseName = @"dgs.sqlite";
    
	// Get the path to the documents directory and append the databaseName
	NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDir = [documentPaths objectAtIndex:0];
	NSString *databasePath = [documentsDir stringByAppendingPathComponent:databaseName];
    
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	// Check if the database has already been created in the users filesystem
	success = [fileManager fileExistsAtPath:databasePath];
    
	if (!success) {    
        // If not then proceed to copy the database from the application to the users filesystem
        
        // Get the path to the database in the application package
        NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:databaseName];
        
        // Copy the database from the package to the users filesystem
        /*BOOL copy_success =*/ [fileManager copyItemAtPath:databasePathFromApp toPath:databasePath error:nil];	
        
        [fileManager release];
    }
    
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        //Database opened successfully
        JWLog("Opened sqlite db...");
    } else {
        //Failed to open database
        JWLog("Failed to open sqlite db");
    }
}

+ (void)closeDatabase {
    sqlite3_close(database);
}

- (id <LoginProtocol>)delegate {
    return self.gameServer.delegate;
}

- (void)setDelegate:(id <LoginProtocol>)delegate {
    self.gameServer.delegate = delegate;
}

// look for any games, our turn to play, where we don't know the SGF
- (void)loadUnknownSGF {
    static sqlite3_stmt *unknownSgfStmt = nil;
    if (unknownSgfStmt == nil) {
        if (sqlite3_prepare_v2(database, "SELECT id FROM games WHERE ourturn = 1 AND finished = 0 AND sgf = '' ORDER BY playorder ASC LIMIT 1", -1, &unknownSgfStmt, NULL) != SQLITE_OK) {
            JWLog("error create fetch games statement '%s'", sqlite3_errmsg(database));
        }
    }
    
    if (sqlite3_step(unknownSgfStmt) == SQLITE_ROW) {
        // got one
        int gameId = sqlite3_column_int(unknownSgfStmt, 0);
        sqlite3_reset(unknownSgfStmt);
        
        Game *game = [[Game alloc] init];
        [game setGameId:gameId];
        
        [self.gameServer getSgfForGame:game onSuccess:^(Game *game) {
            // store data
            
            // update the game information
            static sqlite3_stmt *updateGameStmt = nil;
            if (updateGameStmt == nil) {
                if (sqlite3_prepare_v2(database, "UPDATE games SET sgf = ? WHERE id = ?", -1, &updateGameStmt, NULL) != SQLITE_OK) {
                    JWLog("error create update games statement '%s'", sqlite3_errmsg(database));
                }
            }
            sqlite3_bind_text(updateGameStmt, 1, [[game sgfString] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(updateGameStmt, 2, [game gameId]);
            if (sqlite3_step(updateGameStmt) == SQLITE_DONE) {
                JWLog("got sgf for game %d", [game gameId]);
            } else {
                JWLog("failed to update game %d '%s'", [game gameId], sqlite3_errmsg(database));
            }
            sqlite3_reset(updateGameStmt);
            
            [game release];
            
            // keep trying
            [self loadUnknownSGF];
        }];
        
    } else {
        sqlite3_reset(unknownSgfStmt);
    }
}

- (void)setGameTheirTurn:(int)gameId {
    // update the game setting ourturn = 0
    static sqlite3_stmt *updateGameStmt = nil;
    if (updateGameStmt == nil) {
        if (sqlite3_prepare_v2(database, "UPDATE games SET ourturn = 0, sgf = '' WHERE id = ?", -1, &updateGameStmt, NULL) != SQLITE_OK) {
            JWLog("error create update games statement '%s'", sqlite3_errmsg(database));
        }
    }
    sqlite3_bind_int(updateGameStmt, 1, gameId);
    if (sqlite3_step(updateGameStmt) == SQLITE_DONE) {
    } else {
        JWLog("failed to update game %d '%s'", gameId, sqlite3_errmsg(database));
    }
    sqlite3_reset(updateGameStmt);
}

- (void)setAllTheirTurn {
    // update the games setting ourturn = 0
    static sqlite3_stmt *updateGameStmt = nil;
    if (updateGameStmt == nil) {
        if (sqlite3_prepare_v2(database, "UPDATE games SET ourturn = 0", -1, &updateGameStmt, NULL) != SQLITE_OK) {
            JWLog("error create update games statement '%s'", sqlite3_errmsg(database));
        }
    }
    if (sqlite3_step(updateGameStmt) == SQLITE_DONE) {
    } else {
        JWLog("failed to update games '%s'", sqlite3_errmsg(database));
    }
    sqlite3_reset(updateGameStmt);
}

- (Game *)gameFromResults:(sqlite3_stmt *)stmt {
    // Read the data from the result row
    int gameId = sqlite3_column_int(stmt, 0);
    NSString *opponent = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 3)];
    NSString *sgf = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 4)];
    int ourColor = sqlite3_column_int(stmt, 5);
    NSString *timeLeft = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 7)];
    
    Game *game = [[Game alloc] init];
    [game setGameId:gameId];
    [game setOpponent:opponent];
    [game setColor:(MovePlayer)ourColor];
    const unsigned char *lastMoveString = sqlite3_column_text(stmt, 6);
    if (lastMoveString) {
        NSString *lastMove = [NSString stringWithUTF8String:(char *)lastMoveString];
        [game setLastMove:lastMove];
    }
    [game setTime:timeLeft];
    if (sgf && [sgf length] > 0) {
        [game setSgfString:sgf];
    }
    
    return game;
}

- (Game *)gameFromId:(int)gameId {
    Game *game = nil;
    static sqlite3_stmt *fetchGamesStmt = nil;
    if (fetchGamesStmt == nil) {
        if (sqlite3_prepare_v2(database, "SELECT * FROM games WHERE id = ?", -1, &fetchGamesStmt, NULL) != SQLITE_OK) {
            JWLog("error create fetch games statement '%s'", sqlite3_errmsg(database));
        }
    }
    sqlite3_bind_int(fetchGamesStmt, 1, gameId);
    
    if (sqlite3_step(fetchGamesStmt) == SQLITE_ROW) {
        game = [self gameFromResults:fetchGamesStmt];
    }
    
    sqlite3_reset(fetchGamesStmt);
    
    return game;
}

- (NSArray *)getGamesFromDatabase {
    static sqlite3_stmt *fetchGamesStmt = nil;
    if (fetchGamesStmt == nil) {
        if (sqlite3_prepare_v2(database, "SELECT * FROM games WHERE ourturn = 1 AND finished = 0 ORDER BY playorder ASC", -1, &fetchGamesStmt, NULL) != SQLITE_OK) {
            JWLog("error create fetch games statement '%s'", sqlite3_errmsg(database));
        }
    }
    
	NSMutableArray *dbGames = [NSMutableArray array];
    
    while (sqlite3_step(fetchGamesStmt) == SQLITE_ROW) {
        Game *game = [self gameFromResults:fetchGamesStmt];
        [dbGames addObject:game];
        [game release];
    }
    
    sqlite3_reset(fetchGamesStmt);
    
    // load SGF for unknown games
    [self loadUnknownSGF];
    return dbGames;
}

- (void)cacheGamesToDatabase:(NSArray *)games {
    static sqlite3_stmt *insertGameStmt = nil;
    if (insertGameStmt == nil) {
        if (sqlite3_prepare_v2(database, "INSERT INTO games (id, finished, ourturn, opponent, sgf, ourcolor, timeleft) VALUES (?, 0, 0, '', '', '', '')", -1, &insertGameStmt, NULL) != SQLITE_OK) {
            JWLog(@"error create insert games statement '%s'", sqlite3_errmsg(database));
        }
    }

    for (int playOrder = 0; playOrder < [games count]; playOrder++) {
        Game *game = [games objectAtIndex:playOrder];
        
        // try inserting assuming it's a new game
        sqlite3_bind_int(insertGameStmt, 1, [game gameId]);
        if (sqlite3_step(insertGameStmt) == SQLITE_DONE) {
            JWLog(@"inserted new game %d", [game gameId]);
        } else {
            // this isn't normally a problem. just means that this game already exists in the db.
            //                    JWLog("failed to insert game %d '%s'", [game gameId], sqlite3_errmsg(database));
            
            // check to see if the last play time has changed. if so, we need to refetch the SGF. it means someone has played in meantime
            Game *dbGame = [self gameFromId:[game gameId]];
            if (dbGame != nil && ([game lastMove] != nil)) {
                JWLog(@"our last move: '%@' db: '%@'", [game lastMove], [dbGame lastMove]);
                // compare dates
                if (! [[game lastMove] isEqualToString:[dbGame lastMove]] ) {
                    JWLog(@"last move differs: '%@' db: '%@'", [game lastMove], [dbGame lastMove]);
                    [self setGameTheirTurn:[game gameId]]; // reset the SGF so we fetch it again
                }
            }
        }
        sqlite3_reset(insertGameStmt);
        
        // update the game information
        static sqlite3_stmt *updateGameStmt = nil;
        if (updateGameStmt == nil) {
            if (sqlite3_prepare_v2(database, "UPDATE games SET ourturn = 1, opponent = ?, ourcolor = ?, timeleft = ?, playorder = ?, lastmove = ? WHERE id = ?", -1, &updateGameStmt, NULL) != SQLITE_OK) {
                JWLog(@"error create update games statement '%s'", sqlite3_errmsg(database));
            }
        }
        sqlite3_bind_text(updateGameStmt, 1, [[game opponent] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateGameStmt, 2, [game color]);
        sqlite3_bind_text(updateGameStmt, 3, [[game time] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateGameStmt, 4, playOrder);
        sqlite3_bind_text(updateGameStmt, 5, [[game lastMove] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateGameStmt, 6, [game gameId]);
        if (sqlite3_step(updateGameStmt) == SQLITE_DONE) {
            //                    JWLog("updated game %d", [game gameId]);
        } else {
            JWLog(@"failed to update game %d '%s'", [game gameId], sqlite3_errmsg(database));
        }
        sqlite3_reset(updateGameStmt);
    }
}

- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess {
    if ([DGSAppDelegate refreshThrottled]) {
        onSuccess([self getGamesFromDatabase]);
    } else {
        [DGSAppDelegate resetThrottle];
        [self.gameServer getCurrentGames:^(NSArray *games) {
            // start by clearing all games where it's our turn, since the data we just got will set that properly
            [self setAllTheirTurn];
            [self cacheGamesToDatabase:games];
            onSuccess([self getGamesFromDatabase]);
        }];
    }
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    
    [self setGameTheirTurn:gameId]; // not our turn any more
    
    [self.gameServer playMove:move lastMove:lastMove moveNumber:moveNumber comment:comment gameId:gameId onSuccess:^() {}];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    [self setGameTheirTurn:gameId]; // not our turn any more
    [self.gameServer playHandicapStones:moves comment:comment gameId:gameId onSuccess:onSuccess];
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    [self setGameTheirTurn:gameId]; // not our turn any more
    [self.gameServer markDeadStones:changedStones moveNumber:moveNumber comment:comment gameId:gameId onSuccess:onSuccess];
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess {
    // load game from DB to get freshest copy
    Game *dbGame = [self gameFromId:[game gameId]];
    [self.gameServer getSgfForGame:dbGame onSuccess:onSuccess];
}

// These are all proxied directly to the game server without changes

- (void)logout {
    [self.gameServer logout];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    [self.gameServer loginWithUsername:username password:password];
}

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess {
    [self.gameServer addGame:game onSuccess:onSuccess];
}

- (void)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess {
    [self.gameServer getWaitingRoomGames:onSuccess];
}

- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess {
    [self.gameServer getWaitingRoomGameDetailsForGame:game onSuccess:onSuccess];
}
- (void)joinWaitingRoomGame:(int)gameId comment:(NSString *)comment onSuccess:(void (^)())onSuccess {
    [self.gameServer joinWaitingRoomGame:gameId comment:comment onSuccess:onSuccess];
}

- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess {
    [self.gameServer deleteWaitingRoomGame:gameId onSuccess:onSuccess];
}



@end
