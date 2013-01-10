//
//  CachingGameServer.m
//  DGSPhone

#import "CachingGameServer.h"
#import "JWCache.h"

static JWCache *s_cache;
static NSTimeInterval kDefaultTTL = 15 * 60; // 15 mins
static NSTimeInterval kLongTTL = 7 * 24 * 60 * 60; // 7 days
static NSString * const kGameListKey = @"GameList";
static NSString * const kRunningGameListKey = @"RunningGameList";
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushCache) name:PlayerDidLogoutNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)flushCache {
    [self.cache removeAllObjects];
}

- (NSString *)gameCacheKey:(Game *)game {
    return S(kGameCacheKeyFormat, game.gameId);
}

- (void)removeGameFromGameList:(Game *)game {
    NSMutableOrderedSet *changedGameList = [[self.cache objectForKey:kGameListKey] mutableCopy];

    if (changedGameList) {
        [changedGameList removeObject:game];
        [self.cache setObject:changedGameList forKey:kGameListKey ttl:kDefaultTTL];
        [self.cache removeObjectForKey:S(kGameCacheKeyFormat, game.gameId)];
        
        // We can't do all of the timing calculations client-side, so we'll just
        // have to invalidate the entire running game list.
#warning is there something smarter I can do here?
        [self.cache removeObjectForKey:kRunningGameListKey];
    }
}

- (void)refreshCurrentGames:(OrderedSetBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache removeObjectForKey:kGameListKey];
    [self getCurrentGames:onSuccess onError:onError];
}

- (void)getCurrentGames:(OrderedSetBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache fetchObjectForKey:kGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        [self.gameServer getCurrentGames:^(NSOrderedSet *games) {
            gotObject(games);
            
            for (Game *game in games) {
                [self getSgfForGame:game onSuccess:^(Game *game) {} onError:^(NSError *error) {}];
            }
        } onError:onError];
        return nil; // nothing to return here.
    } completion:^(NSOrderedSet *gameList) {
        onSuccess(gameList);
    }];
}

- (void)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache removeObjectForKey:kRunningGameListKey];
    [self getRunningGames:onSuccess onError:onError];
}

- (void)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache fetchObjectForKey:kRunningGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        [self.gameServer getRunningGames:^(GameList *games) {
            gotObject(games);
        } onError:onError];
        return nil; // nothing to return here.
    } completion:^(GameList *gameList) {
        onSuccess(gameList);
    }];
}

- (void)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    
    [self.gameServer playMove:move lastMove:lastMove moveNumber:moveNumber comment:comment game:game onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer playHandicapStones:moves comment:comment game:game onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    [self.gameServer markDeadStones:changedStones moveNumber:moveNumber comment:comment game:game onSuccess:^() {} onError:onError];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
}

- (void)getSgfForGame:(Game *)game onSuccess:(GameBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache fetchObjectForKey:[self gameCacheKey:game] ttl:kLongTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
#warning what happens if we lost the game from the cache?
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

- (void)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.gameServer addGamesToGameList:gameList onSuccess:onSuccess onError:onError];
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
