//
//  GameServer.h
//  Protocol representing a game server.
//

#import <Foundation/Foundation.h>
#import "NewGame.h"
#import "Game.h"
#import "Invite.h"
#import "GameList.h"
#import "MKNetworkOperation.h"

@class MKNetworkOperation;

extern NSString * const PlayerDidLoginNotification;
extern NSString * const PlayerDidLogoutNotification;
extern NSString * const NetworkErrorNotification;

typedef void(^EmptyBlock)(void);
typedef void(^GameListBlock)(GameList *gameList);
typedef void(^GameBlock)(Game *game);
typedef void(^NewGameBlock)(NewGame *game);
typedef void(^ErrorBlock)(NSError *error);

@protocol GameServerProtocol

+ (id<GameServerProtocol>)sharedGameServer;

- (NSOperation *)logout:(ErrorBlock)onError;
- (NSOperation *)loginWithUsername:(NSString *)username
                          password:(NSString *)password
                         onSuccess:(EmptyBlock)onSuccess
                           onError:(ErrorBlock)onError;

- (NSArray *)cookiesForCurrentUser;

- (NSOperation *)addGame:(NewGame *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)refreshCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getSgfForGame:(Game *)game onSuccess:(GameBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getInviteDetails:(Invite *)invite onSuccess:(void (^)(Invite *invite))onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)answerInvite:(Invite *)invite accepted:(BOOL)accepted onSuccess:(void (^)(void))onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getWaitingRoomGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(NewGameBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)joinWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)deleteWaitingRoomGame:(int)gameId onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;

- (NSOperation *)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;
- (NSOperation *)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess  onError:(ErrorBlock)onError;
- (NSOperation *)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(EmptyBlock)onSuccess onError:(ErrorBlock)onError;

- (void)openGameInBrowser:(Game *)game;
@end
