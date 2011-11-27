//
//  DbHelper.m
//  DGSPhone
//
//  Created by adam miller on 11/24/11.
//

#import "/usr/include/sqlite3.h"

#import "DbHelper.h"

@implementation DbHelper


// look for any games, our turn to play, where we don't know the SGF
+ (void)loadUnknownSGF:(id<GameServerProtocol>)gs {
    sqlite3 *database = [DGSAppDelegate database];
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

        [gs getSgfForGame:game onSuccess:^(Game *game) {
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
            [DbHelper loadUnknownSGF:gs];
        }];
        
    } else {
        sqlite3_reset(unknownSgfStmt);
    }

}

+ (void)setGameTheirTurn:(int)gameId {
    // update the game setting ourturn = 0
    sqlite3 *database = [DGSAppDelegate database];
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

+ (void)setAllTheirTurn {
    // update the games setting ourturn = 0
    sqlite3 *database = [DGSAppDelegate database];
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

+ (Game *)gameFromResults:(sqlite3_stmt *)stmt {
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

+ (Game *)gameFromId:(int)gameId {
    Game *game = nil;
    sqlite3 *database = [DGSAppDelegate database];
    static sqlite3_stmt *fetchGamesStmt = nil;
    if (fetchGamesStmt == nil) {
        if (sqlite3_prepare_v2(database, "SELECT * FROM games WHERE id = ?", -1, &fetchGamesStmt, NULL) != SQLITE_OK) {
            JWLog("error create fetch games statement '%s'", sqlite3_errmsg(database));
        }
    }
    sqlite3_bind_int(fetchGamesStmt, 1, gameId);
        
    if (sqlite3_step(fetchGamesStmt) == SQLITE_ROW) {
        game = [DbHelper gameFromResults:fetchGamesStmt];
    }
    
    sqlite3_reset(fetchGamesStmt);
    
    return game;
}

@end
