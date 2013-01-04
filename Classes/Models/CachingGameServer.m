//
//  CachingGameServer.m
//  DGSPhone

#import "CachingGameServer.h"
#import "JWCache.h"

static JWCache *s_cache;
static NSTimeInterval kDefaultTTL = 15 * 60; // 15 mins
static NSTimeInterval kLongTTL = 7 * 24 * 60 * 60; // 7 days
static NSString * const kGameListKey = @"GameList";
static NSString * const kGameCacheKeyFormat = @"Game-%d";

@interface CachingGameServer ()

@property(nonatomic, weak) JWCache *cache;

@end

@implementation CachingGameServer

+ (void)initialize {
    s_cache = [[JWCache alloc] init];
}

+ (id<GameServerProtocol>)sharedGameServer {
    static CachingGameServer *sharedGameServer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedGameServer = [[self alloc] initWithGameServer:[[NSClassFromString(SERVER_CLASS) alloc] init]];
    });
    return sharedGameServer;
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

- (NSString *)gameCacheKey:(Game *)game {
    return S(kGameCacheKeyFormat, game.gameId);
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
        [self.cache removeObjectForKey:S(kGameCacheKeyFormat, gameId)];
    }
}

- (void)refreshCurrentGames:(void (^)(NSArray *gameList))onSuccess onError:(ErrorBlock)onError {
    [self.cache removeObjectForKey:kGameListKey];
    [self getCurrentGames:onSuccess onError:onError];
}

- (void)getCurrentGames:(void (^)(NSArray *gameList))onSuccess onError:(ErrorBlock)onError {
    [self.cache fetchObjectForKey:kGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        [self.gameServer getCurrentGames:^(NSArray *games) {
            gotObject(games);
            
            for (Game *game in games) {
                [self getSgfForGame:game onSuccess:^(Game *game) {} onError:^(NSError *error) {}];
            }
        } onError:onError];
        return nil; // nothing to return here.
    } completion:^(NSArray *gameList) {
        onSuccess(gameList);
    }];
}

- (void)getRunningGames:(ListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.gameServer getRunningGames:onSuccess onError:onError];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    
    [self.gameServer playMove:move lastMove:lastMove moveNumber:moveNumber comment:comment gameId:gameId onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer playHandicapStones:moves comment:comment gameId:gameId onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment gameId:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer markDeadStones:changedStones moveNumber:moveNumber comment:comment gameId:gameId onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:gameId];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)getSgfForGame:(Game *)game onSuccess:(void (^)(Game *game))onSuccess onError:(ErrorBlock)onError {
    [self.cache fetchObjectForKey:[self gameCacheKey:game] ttl:kLongTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        gotObject(game);
        return nil;
    } completion:^(Game *cachedGame) {
        if (game.moveId <= cachedGame.moveId && cachedGame.sgfString) {
            // don't need any more information, just continue with the cached game
            onSuccess(cachedGame);
        } else {
            // re-fetch the sgf, and re-cache the game
            [self.gameServer getSgfForGame:game onSuccess:^(Game *gameWithSGF) {
                [self.cache setObject:gameWithSGF forKey:[self gameCacheKey:gameWithSGF] ttl:kLongTTL];
                onSuccess(gameWithSGF);
            } onError:onError];
        }
    }];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError{
    [self.cache removeAllObjects];
    [self.gameServer loginWithUsername:username password:password onSuccess:onSuccess onError:onError];
}

// These are all proxied directly to the game server without changes
#pragma mark - Game Server proxied methods

- (void)logout:(ErrorBlock)onError {
    [self.gameServer logout:onError];
}

- (void)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer addGame:game onSuccess:onSuccess onError:onError];
}

- (void)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess onError:(ErrorBlock)onError {
    [self.gameServer getWaitingRoomGames:onSuccess onError:onError];
}

- (void)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess onError:(ErrorBlock)onError {
    [self.gameServer getWaitingRoomGameDetailsForGame:game onSuccess:onSuccess onError:onError];
}
- (void)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer joinWaitingRoomGame:gameId onSuccess:onSuccess onError:onError];
}

- (void)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer deleteWaitingRoomGame:gameId onSuccess:onSuccess onError:onError];
}



@end
