//
//  GameServer.h
//  Protocol representing a game server.
//

#import <Foundation/Foundation.h>
#import "NewGame.h"
#import "Game.h"
#import "LoginProtocol.h"
#import "GameList.h"

extern NSString * const PlayerDidLoginNotification;
extern NSString * const PlayerDidLogoutNotification;

typedef void(^EmptyBlock)();
typedef void(^ListBlock)(NSArray *list);
typedef void(^GameListBlock)(GameList *gameList);
typedef void(^GameBlock)(Game *game);
typedef void(^NewGameBlock)(NewGame *game);
typedef void(^ErrorBlock)(NSError *error);

@protocol GameServerProtocol

@property(nonatomic, assign) id <LoginProtocol> delegate;

// Logic tests can't test anything that uses the native iPhone functionality.
// Therefore, we don't want to compile anything that hits the network
// if we're building the logic tests bundle. It should define LOGIC_TEST_MODE.
#ifndef LOGIC_TEST_MODE

+ (id<GameServerProtocol>)sharedGameServer;

- (void)logout:(ErrorBlock)onError;
- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(EmptyBlock)onSuccess
                  onError:(ErrorBlock)onError;

- (void)addGame:(NewGame *)game onSuccess:(EmptyBlock)onSuccess;
- (void)getCurrentGames:(ListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)refreshCurrentGames:(ListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getSgfForGame:(Game *)game onSuccess:(GameBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getWaitingRoomGames:(GameListBlock)onSuccess;
- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(NewGameBlock)onSuccess;
- (void)joinWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess;
- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess;


- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(EmptyBlock)onSuccess;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(EmptyBlock)onSuccess;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(EmptyBlock)onSuccess;

#endif

@end
