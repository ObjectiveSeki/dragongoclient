//
//  DGS.h
//  DGSPhone
//
//  Created by Justin Weiss on 6/3/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginProtocol.h"
#import "Game.h"
#import "NewGame.h"

#ifndef LOGIC_TEST_MODE
#import "ASIHTTPRequest.h"

typedef void (^ASIHTTPRequestBlock)(ASIHTTPRequest *request, NSString *responseString);
#endif

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

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess;
- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess;
- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess;
- (void)getWaitingRoomGames:(void (^)(NSArray *gameList))onSuccess;
- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess;
- (void)joinWaitingRoomGame:(int)gameId comment:(NSString *)comment onSuccess:(void (^)())onSuccess;
- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess;


- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;

// Starts an asynchronous request, calling onSuccess when the request finishes.
- (void)performRequest:(ASIHTTPRequest *)request onSuccess:(ASIHTTPRequestBlock)onSuccess;

#endif

- (NSString *)sgfCoordsWithRow:(int)row column:(int)col boardSize:(int)boardSize;

// Internal, but these have to be exposed so the logic tests can hit them
- (NSArray *)gamesFromCSV:(NSString *)csvData;
- (NSArray *)gamesFromTable:(NSString *)htmlString;
- (NSArray *)gamesFromWaitingRoomTable:(NSString *)htmlString;
- (NewGame *)gameFromWaitingRoomDetailTable:(NSString *)htmlString game:(NewGame *)game;
@end
