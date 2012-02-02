//
//  CachingGameServer.h
//  DGSPhone
//
//  Wraps a class that conforms to the GameServerProtocol, but provides local
//  caching of games and moves to reduce network activity and enable offline
//  play.
//

#import <Foundation/Foundation.h>
#import "GameServerProtocol.h"

@interface CachingGameServer : NSObject<GameServerProtocol>

@property(nonatomic, retain) id<GameServerProtocol> gameServer;

- (id)initWithGameServer:(id<GameServerProtocol>)aGameServer;

// Creates the database (if necessary) representing the cache store, 
// and opens the connection. This must be called before calling any other
// methods on this class.
+ (void)checkAndCreateDatabase;

// Closes the database connection. This should be called before the app closes.
+ (void)closeDatabase;

- (void)logout;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess;
- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess;
- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess;
- (void)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess;
- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess;
- (void)joinWaitingRoomGame:(int)gameId comment:(NSString *)comment onSuccess:(void (^)())onSuccess;
- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess;


- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess;
@end
