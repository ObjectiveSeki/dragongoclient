//
//  CachingGameServer.m
//  DGSPhone

#import "CachingGameServer.h"
#import "DGSPhoneAppDelegate.h"
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateGameLists) name:ReceivedNewGamesNotification object:nil];
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
    MutableGameList *changedGameList = [[self.cache objectForKey:kGameListKey] mutableCopy];

    if (changedGameList) {
        [changedGameList removeGame:game];
        
        // Refresh the TTL, so we don't have to hit the server again soon
        [self.cache setObject:changedGameList forKey:kGameListKey ttl:kDefaultTTL];
        [self.cache removeObjectForKey:S(kGameCacheKeyFormat, game.gameId)];
        
        // We can't do all of the timing calculations client-side, so we'll just
        // have to invalidate the entire running game list.
        [self.cache removeObjectForKey:kRunningGameListKey];
    }
}

// If we remove a game, but later fail to actually play a move, we'll need to
// add it back to the game list. This more or less reverses removeGameFromGameList
- (void)addGameBackToGameList:(Game *)game {
    MutableGameList *changedGameList = [[self.cache objectForKey:kGameListKey] mutableCopy];
    
    if (changedGameList) {
        [changedGameList addGames:[NSOrderedSet orderedSetWithObject:game]];
        
        [self.cache setObject:changedGameList forKey:kGameListKey ttl:kDefaultTTL];
        [self.cache setObject:game forKey:S(kGameCacheKeyFormat, game.gameId) ttl:kLongTTL];
    }
}

- (void)invalidateGameLists {
    [self.cache removeObjectForKey:kRunningGameListKey];
    [self.cache removeObjectForKey:kGameListKey];
}

- (NSOperation *)refreshCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache removeObjectForKey:kGameListKey];
    return [self getCurrentGames:onSuccess onError:onError];
}

- (NSOperation *)getCurrentGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    return [self.cache fetchObjectForKey:kGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        return [self.gameServer getCurrentGames:^(GameList *gameList) {
            gotObject(gameList);
            
            for (Game *game in gameList.games) {
                [self getSgfForGame:game onSuccess:^(Game *game) {} onError:^(NSError *error) {}];
            }
        } onError:onError];
    } completion:^(GameList *gameList) {
        onSuccess(gameList);
    }];
}

- (NSOperation *)refreshRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    [self.cache removeObjectForKey:kRunningGameListKey];
    return [self getRunningGames:onSuccess onError:onError];
}

- (NSOperation *)getRunningGames:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    return [self.cache fetchObjectForKey:kRunningGameListKey ttl:kDefaultTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
        return [self.gameServer getRunningGames:^(GameList *games) {
            gotObject(games);
        } onError:onError];
    } completion:^(GameList *gameList) {
        onSuccess(gameList);
    }];
}

- (NSOperation *)playMove:(Move *)move lastMove:(Move *)lastMove moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    
    NSOperation *op = [self.gameServer playMove:move lastMove:lastMove moveNumber:moveNumber comment:comment game:game onSuccess:^() {} onError:^(NSError *error) {
        [self addGameBackToGameList:game];
        onError(error);
    }];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
    return op;
}

- (NSOperation *)playHandicapStones:(NSArray *)moves comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    NSOperation *op = [self.gameServer playHandicapStones:moves comment:comment game:game onSuccess:^() {} onError:^(NSError *error) {
        [self addGameBackToGameList:game];
        onError(error);
    }];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
    return op;
}

- (NSOperation *)markDeadStones:(NSArray *)changedStones moveNumber:(int)moveNumber comment:(NSString *)comment game:(Game *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    NSOperation *op = [self.gameServer markDeadStones:changedStones moveNumber:moveNumber comment:comment game:game onSuccess:^() {} onError:^(NSError *error) {
        [self addGameBackToGameList:game];
        onError(error);
    }];
    
    [self removeGameFromGameList:game];
    
    onSuccess(); // cheat and call it right away for speed
    return op;
}

- (NSOperation *)getSgfForGame:(Game *)game onSuccess:(GameBlock)onSuccess onError:(ErrorBlock)onError {
    return [self.cache fetchObjectForKey:[self gameCacheKey:game] ttl:kLongTTL fetchBlock:^id(JWCache *cache, CacheCallbackBlock gotObject) {
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

- (NSOperation *)loginWithUsername:(NSString *)username password:(NSString *)password onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError{
    [self flushCache];
    return [self.gameServer loginWithUsername:username password:password onSuccess:onSuccess onError:onError];
}

// These are all proxied directly to the game server without changes
#pragma mark - Game Server proxied methods

- (NSOperation *)logout:(ErrorBlock)onError {
    return [self.gameServer logout:onError];
}

- (NSOperation *)addGame:(NewGame *)game onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer addGame:game onSuccess:onSuccess onError:onError];
}

- (NSOperation *)getWaitingRoomGames:(void (^)(GameList *gameList))onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer getWaitingRoomGames:onSuccess onError:onError];
}

- (NSOperation *)addGamesToGameList:(GameList *)gameList onSuccess:(GameListBlock)onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer addGamesToGameList:gameList onSuccess:onSuccess onError:onError];
}

- (NSOperation *)getWaitingRoomGameDetailsForGame:(NewGame *)game onSuccess:(void (^)(NewGame *game))onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer getWaitingRoomGameDetailsForGame:game onSuccess:onSuccess onError:onError];
}
- (NSOperation *)joinWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer joinWaitingRoomGame:gameId onSuccess:onSuccess onError:onError];
}

- (NSOperation *)getInviteDetails:(Invite *)invite onSuccess:(void (^)(Invite *))onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer getInviteDetails:invite onSuccess:onSuccess onError:onError];
}

- (NSOperation *)deleteWaitingRoomGame:(int)gameId onSuccess:(void (^)())onSuccess onError:(ErrorBlock)onError {
    return [self.gameServer deleteWaitingRoomGame:gameId onSuccess:onSuccess onError:onError];
}

- (void)openGameInBrowser:(Game *)game {
    [self.gameServer openGameInBrowser:game];
}

- (NSArray *)cookiesForCurrentUser {
    return [self.gameServer cookiesForCurrentUser];
}

@end
