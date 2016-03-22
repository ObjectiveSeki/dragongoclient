//
//  DGSPushServer.m
//  DGSPhone
//
//  Created by Justin Weiss on 1/19/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "DGSPushServer.h"
#import "Player.h"
#import "UIDevice+ExtraDeviceDetails.h"

#define APNSDeviceIdUserDefaultsKey @"APNSDeviceId"

@interface DGSPushServer ()

@property (nonatomic, strong) NSOperationQueue *delayedNetworkOperationQueue;
@end

@implementation DGSPushServer

+ (DGSPushServer *)sharedPushServer {
    static DGSPushServer *sharedPushServer = nil;
#ifdef PUSH_ENABLED
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedPushServer = [[self alloc] init];
    });
#endif
    return sharedPushServer;
}

- (id)init
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *headerFields = @{ @"X-client-identifier": @"Dragon Go Client iOS",
                                    @"X-bundle-identifier": [infoDictionary objectForKey:@"CFBundleIdentifier"],
                                    @"X-client-version": S(@"Version %@ (%@)", [infoDictionary objectForKey:@"CFBundleShortVersionString"], [infoDictionary objectForKey:@"CFBundleVersion"]),
                                    @"X-ios-platform": [[UIDevice currentDevice] platform],
                                    @"X-ios-version": [[UIDevice currentDevice] systemVersion]};

    self = [super initWithHostName:PUSH_HOST customHeaderFields:headerFields];
    if (self) {
    }
    return self;
}

# pragma mark - Overridden MKNetworkKit Methods

- (MKNetworkOperation *)operationWithPath:(NSString *)path params:(NSDictionary *)body httpMethod:(NSString *)method {
    return [super operationWithPath:path params:body httpMethod:method ssl:PUSH_USE_SSL];
}


# pragma mark - Push management methods

- (void)setupRemoteNotifications {
    [self beginQueueingRequestsRequiringLogin];
    if ([Player currentPlayer].userId) {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self didFailToRetrieveDeviceId];
}

- (void)setDeviceIdFromResponse:(NSDictionary *)response {
    NSNumber *deviceId = response[@"id"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:APNSDeviceIdUserDefaultsKey];
    [self runQueuedRequests];
}

- (NSNumber *)deviceId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:APNSDeviceIdUserDefaultsKey];
}

- (BOOL)isPushEnabled {
    return [self.deviceId boolValue];
}

- (BOOL)isLoggedIn {
    return [Player currentPlayer] != nil;
}

- (void)didFailToRetrieveDeviceId {
    [self clearQueueingRequestsRequiringLogin];
}

- (void)beginQueueingRequestsRequiringLogin {
    NSOperationQueue *delayedNetworkOperationQueue = [[NSOperationQueue alloc] init];
    delayedNetworkOperationQueue.name = @"Network requests delayed until login";
    [delayedNetworkOperationQueue setSuspended:YES];
    self.delayedNetworkOperationQueue = delayedNetworkOperationQueue;
}

- (void)queueOrSaveOperation:(MKNetworkOperation *)operation {
    if([self isPushEnabled]) {
        [self enqueueOperation:operation];
    } else {
        [self.delayedNetworkOperationQueue addOperationWithBlock:^{
            [self enqueueOperation:operation];
        }];
    }
}

- (void)runQueuedRequests {
    NSOperationQueue *delayedNetworkOperationQueue = self.delayedNetworkOperationQueue;
    self.delayedNetworkOperationQueue = nil;
    [delayedNetworkOperationQueue setSuspended:NO];
}

- (void)clearQueueingRequestsRequiringLogin {
    self.delayedNetworkOperationQueue = nil;
}

#pragma mark - Push Server methods

#pragma mark - Push Tokens

// Updates the push token, creating it if we don't already hold a reference to one.
- (MKNetworkOperation *)updateAPNSDeviceToken:(NSData *)token completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    static NSString *updateDeviceTokenPathFormat = @"players/%@/devices/%@.json";
    NSNumber *deviceId = [self deviceId];

    if (deviceId) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[token base64EncodedString], @"device[encoded_device_token]", nil];

        MKNetworkOperation *op = [self operationWithPath:S(updateDeviceTokenPathFormat, [Player currentPlayer].userId, deviceId) params:params httpMethod:@"PUT"];

        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            [self setDeviceIdFromResponse:[completedOperation responseJSON]];
            completionHandler();
        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
            [self didFailToRetrieveDeviceId];
            errorHandler(theError);

        }];

        [self enqueueOperation:op];
        return op;
    } else {
        return [self createAPNSDeviceToken:token completionHandler:completionHandler errorHandler:errorHandler];
    }
}

- (MKNetworkOperation *)createAPNSDeviceToken:(NSData *)token completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    static NSString *createDeviceTokenPathFormat = @"players/%@/devices.json";
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[token base64EncodedString], @"device[encoded_device_token]", nil];

    MKNetworkOperation *op = [self operationWithPath:S(createDeviceTokenPathFormat, [Player currentPlayer].userId) params:params httpMethod:@"POST"];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        [self setDeviceIdFromResponse:[completedOperation responseJSON]];
        completionHandler();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        [self didFailToRetrieveDeviceId];
        errorHandler(theError);
    }];

    [self enqueueOperation:op];
    return op;
}

- (MKNetworkOperation *)deleteAPNSDeviceTokenForPlayerId:(NSNumber *)playerId completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    if (!playerId) {
        return nil;
    }

    static NSString *deleteDeviceTokenPathFormat = @"players/%@/devices/%@.json";
    NSNumber *deviceId = [self deviceId];

    if (deviceId) {
        // Remove the token regardless of whether this call succeeds, because we can always get it back later if we need it.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:APNSDeviceIdUserDefaultsKey];
        MKNetworkOperation *op = [self operationWithPath:S(deleteDeviceTokenPathFormat, playerId, deviceId) params:nil httpMethod:@"DELETE"];

        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            completionHandler();
        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
            errorHandler(theError);
        }];

        [self enqueueOperation:op];
        return op;
    } else {
        // pretend success
        completionHandler();
        return nil;
    }
}

#pragma mark - Cookies

- (MKNetworkOperation *)createLoginCookies:(NSArray *)cookies completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    if ([cookies count] == 0) {
        [self didFailToRetrieveDeviceId];
        return nil;
    }

    static NSString *createSessionPathFormat = @"players/%@/session.json";
    NSMutableDictionary *params = [self paramsFromLoginCookies:cookies];

    MKNetworkOperation *op = [self operationWithPath:S(createSessionPathFormat, [Player currentPlayer].userId) params:params httpMethod:@"POST"];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionHandler();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        [self didFailToRetrieveDeviceId];
        errorHandler(theError);
    }];

    [self enqueueOperation:op];
    return op;
}

- (NSMutableDictionary *)paramsFromLoginCookies:(NSArray *)cookies {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    params[@"session[cookie]"] = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies][@"Cookie"];
    params[@"session[expires_at]"] = [cookies valueForKeyPath:@"@min.expiresDate"];
    return params;
}

#pragma mark - Game updates
- (MKNetworkOperation *)updateGameList:(GameList *)gameList completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    static NSString *pathFormat = @"players/%@/games.json";
    NSMutableDictionary *params = [self paramsFromGameList:gameList];

    MKNetworkOperation *op = [self operationWithPath:S(pathFormat, [Player currentPlayer].userId) params:params httpMethod:@"PUT"];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionHandler();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        errorHandler(theError);
    }];

    [self queueOrSaveOperation:op];
    return op;
}

- (MKNetworkOperation *)fetchGamesUpdatedSince:(NSString *)lastKnownMove completionHandler:(void (^)(NSArray *))completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    if (![self isLoggedIn]) {
        return nil;
    }
    
    static NSString *pathFormat = @"players/%@/games.json%@";
    NSString *getParams = @"";
    
    if (lastKnownMove) {
        getParams = S(@"?after=%@", [lastKnownMove stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
    }
    
    MKNetworkOperation *op = [self operationWithPath:S(pathFormat, [Player currentPlayer].userId, getParams) params:@{} httpMethod:@"GET"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        // parse game data
        completionHandler(completedOperation.responseJSON);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        errorHandler(theError);
    }];
    
    [self queueOrSaveOperation:op];
    return op;
}

- (MKNetworkOperation *)playMoveInGame:(Game *)game completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler {
    static NSString *pathFormat = @"players/%@/games/%d/move.json";

    MKNetworkOperation *op = [self operationWithPath:S(pathFormat, [Player currentPlayer].userId, game.gameId)
                                              params:nil
                                          httpMethod:@"POST"];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionHandler();
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *theError) {
        errorHandler(theError);
    }];

    [self queueOrSaveOperation:op];
    return op;
}

- (NSMutableDictionary *)paramsFromGameList:(GameList *)gameList {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    for (Game *game in gameList.games) {
        params[S(@"games[%d][opponent_name]", game.gameId)] = game.opponent;
        params[S(@"games[%d][updated_at]", game.gameId)] = game.lastMove;
    }
    return params;
}

@end
