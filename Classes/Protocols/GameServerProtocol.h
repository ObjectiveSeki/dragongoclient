//
//  GameServer.h
//  Protocol representing a game server.
//

#import <Foundation/Foundation.h>
#import "NewGame.h"
#import "Game.h"
#import "GameList.h"

extern NSString * const PlayerDidLoginNotification;
extern NSString * const PlayerDidLogoutNotification;

typedef void(^EmptyBlock)();
typedef void(^GameListBlock)(GameList *gameList);
typedef void(^GameBlock)(Game *game);
typedef void(^NewGameBlock)(NewGame *game);
typedef void(^ErrorBlock)(NSError *error);

@protocol GameServerProtocol

+ (id<GameServerProtocol>)sharedGameServer;

- (void)logout:(ErrorBlock)onError;
- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(EmptyBlock)onSuccess
                  onError:(ErrorBlock)onError;

- (void)addGame:(NewGame *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)refreshCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getSgfForGame:(Game *)game onSuccess:(GameBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getWaitingRoomGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(NewGameBlock)onSuccess onError:(ErrorBlock)onError;
- (void)joinWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;


- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess  onError:(ErrorBlock)onError;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;

@end
