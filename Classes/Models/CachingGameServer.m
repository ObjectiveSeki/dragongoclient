//
//  CachingGameServer.m
//  DGSPhone

#import "CachingGameServer.h"
#import "JWCache.h"

static JWCache *s_cache;
static NSTimeInterval kDefaultTTL = 5 * 60;
static NSString * const kGameListKey = @"GameList";

@interface CachingGameServer ()

@property(nonatomic, weak) JWCache *cache;

@end

@implementation CachingGameServer

+ (void)initialize {
    s_cache = [[JWCache alloc] init];
}

- (id)initWithGameServer:(id<GameServerProtocol>)aGameServer;
{
    self = [super init];
    if (self) {
        _gameServer = aGameServer;
        _cache = s_cache;
    }
    return self;
}

- (id <LoginProtocol>)delegate {
    return self.gameServer.delegate;
}

- (void)setDelegate:(id <LoginProtocol>)delegate {
    self.gameServer.delegate = delegate;
}

- (void)removeGameFromGameList:(int)gameId {
    NSArray *gameList = [self.cache objectForKey:kGameListKey];
    NSMutableArray *changedGameList = [gameList mutableCopy];
    if (changedGameList) {
        NSUInteger gameIndex = [changedGameList indexOfObjectPassingTest:^BOOL(Game *game, NSUInteger idx, BOOL *stop) {
            return game.gameId == gameId;
        }];
        [changedGameList removeObjectAtIndex:gameIndex];
        [self.cache setObject:changedGameList forKey:kGameListKey ttl:kDefaultTTL];
    }
}

- (void)refreshCurrentGames:(void (^)(NSArray *gameList))onSuccess {
    [self.cache removeObjectForKey:kGameListKey];
    [self getCurrentGames:onSuccess];
}

- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess {
    [self.cache fetchObjectForKey:kGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        [self.gameServer getCurrentGames:^(NSArray *games) {
            gotObject(games);
        }];
        return nil; // nothing to return here.
    } completion:^(NSArray *gameList) {
        onSuccess(gameList);
    }];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    
    [self.gameServer playMove:move lastMove:lastMove moveNumber:moveNumber comment:comment gameId:gameId onSuccess:^() {}];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    [self.gameServer playHandicapStones:moves comment:comment gameId:gameId onSuccess:^() {}];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess {
    [self.gameServer markDeadStones:changedStones moveNumber:moveNumber comment:comment gameId:gameId onSuccess:^() {}];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess {
    [self.gameServer getSgfForGame:game onSuccess:onSuccess];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    [self.cache removeAllObjects];
    [self.gameServer loginWithUsername:username password:password];
}

// These are all proxied directly to the game server without changes
#pragma mark - Game Server proxied methods

- (void)logout {
    [self.gameServer logout];
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
- (void)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess {
    [self.gameServer joinWaitingRoomGame:gameId onSuccess:onSuccess];
}

- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess {
    [self.gameServer deleteWaitingRoomGame:gameId onSuccess:onSuccess];
}



@end
