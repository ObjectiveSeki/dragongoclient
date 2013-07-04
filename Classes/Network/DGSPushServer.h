//
//  DGSPushServer.h
//  DGSPhone
//
//  Created by Justin Weiss on 1/19/13.
//  Copyright (c) 2013 Justin Weiss. All rights reserved.
//

#import "MKNetworkKit.h"

@interface DGSPushServer : MKNetworkEngine

+ (DGSPushServer *)sharedPushServer;

- (void)registerForRemoteNotifications;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (MKNetworkOperation *)createAPNSDeviceToken:(NSData *)token completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;
- (MKNetworkOperation *)updateAPNSDeviceToken:(NSData *)token completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;
- (MKNetworkOperation *)deleteAPNSDeviceTokenForPlayerId:(NSNumber *)playerId completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;

- (MKNetworkOperation *)createLoginCookies:(NSArray *)cookies completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;

- (MKNetworkOperation *)updateGameList:(GameList *)gameList completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;
- (MKNetworkOperation *)fetchGamesUpdatedSince:(NSString *)lastKnownMove completionHandler:(void (^)(NSArray *games))completionHandler errorHandler:(MKNKErrorBlock)errorHandler;

- (MKNetworkOperation *)playMoveInGame:(Game *)game completionHandler:(EmptyBlock)completionHandler errorHandler:(MKNKErrorBlock)errorHandler;

@end
