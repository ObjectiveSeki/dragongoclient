//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Avvo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginProtocol.h"
#import "Game.h"
#import "NewGame.h"

@interface DGS : NSObject {
	id <LoginProtocol> delegate;
}

@property(nonatomic, assign) id <LoginProtocol> delegate;


// Logic tests can't test anything that uses the native iPhone functionality.
// Therefore, we don't want to compile anything that hits the network
// if we're building the logic tests bundle. It should define LOGIC_TEST_MODE.
#ifndef LOGIC_TEST_MODE

- (void)logout;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

- (void)getCurrentGames;
- (void)getSgfForGame:(Game *)game;
- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId;
- (void)addGame:(NewGame *)game;
#endif

- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;

// Internal, but these have to be exposed so the logic tests can hit them
- (NSArray *)gamesFromCSV:(NSString *)csvData;
- (NSArray *)gamesFromTable:(NSString *)htmlString;

@end
