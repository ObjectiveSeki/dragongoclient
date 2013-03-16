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

- (MKNetworkOperation *)createAPNSDeviceToken:(NSData *)token completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;
- (MKNetworkOperation *)updateAPNSDeviceToken:(NSData *)token completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;
- (MKNetworkOperation *)deleteAPNSDeviceTokenForPlayerId:(NSNumber *)playerId completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;

- (MKNetworkOperation *)createLoginCookies:(NSArray *)cookies completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;
#warning implement this
// - (MKNetworkOperation *)deleteLoginCookies:(NSArray *)cookies completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;

- (MKNetworkOperation *)updateGameList:(GameList *)gameList completion:(EmptyBlock)completion error:(MKNKErrorBlock)error;

@end
