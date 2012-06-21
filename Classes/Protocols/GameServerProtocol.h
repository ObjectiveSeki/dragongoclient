//
//  GameServer.h
//  Protocol representing a game server.
//

#import <Foundation/Foundation.h>
#import "NewGame.h"
#import "Game.h"
#import "LoginProtocol.h"
#import "GameList.h"

@protocol GameServerProtocol

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
- (void)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess;
- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess;
- (void)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess;


- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;

#endif

@end
